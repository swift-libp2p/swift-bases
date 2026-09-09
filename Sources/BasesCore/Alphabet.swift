//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2026 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// An immutable, ASCII base alphabet paired with a 256 entry reverse lookup table.
///
/// Every alphabet in this package is a `static let` of this type, so the reverse table is
/// built once per process rather than per call. Before 0.4.0 each module rebuilt its
/// alphabet on every operation.
///
/// - Note: The radix is limited to 255 because ``sentinel`` (`0xFF`) marks "not in this
///   alphabet" in ``decodingTable``. An alphabet with 256 digits, such as base256emoji,
///   needs a scalar-keyed table instead, since its digits are not single ASCII bytes.
public struct Alphabet: Hashable, Sendable {

    /// The ``decodingTable`` entry for a character that is not part of the alphabet.
    public static let sentinel: UInt8 = 0xFF

    /// The `=` character the block encodings use to pad a partial final block.
    public static let paddingCharacter: UInt8 = 0x3D

    /// The alphabet's digits, in value order: `characters[v]` renders the value `v`.
    public let characters: [UInt8]

    /// A 256 entry table mapping a character's byte to its value, or ``sentinel``.
    public let decodingTable: [UInt8]

    /// Extra characters accepted when decoding, mapped to the value they stand for.
    ///
    /// Used where a variant historically tolerated another variant's digits — base64url
    /// accepts `+` and `/` alongside `-` and `_`.
    public let aliases: [UInt8: UInt8]

    /// `⌊log2(radix)⌋` — the guaranteed number of bits carried by one digit.
    public let bitsPerDigitFloor: Int

    /// `⌈log2(radix)⌉` — the most bits one digit can carry.
    public let bitsPerDigitCeil: Int

    /// The number of digits in the alphabet.
    public var radix: Int { characters.count }

    /// The digit representing zero, used to render a leading zero byte in the positional
    /// (`BaseX`) encodings.
    public var leader: UInt8 { characters[0] }

    /// The alphabet's digits as a `String`, in value order.
    public var characterString: String { String(decoding: characters, as: UTF8.self) }

    /// Whether ``decodingTable`` also maps the opposite case of each letter.
    public let isCaseInsensitive: Bool

    /// Builds an alphabet from its digits, in value order.
    ///
    /// - Parameters:
    ///   - characters: The alphabet's digits. Must contain between 2 and 255 distinct
    ///     ASCII characters.
    ///   - caseInsensitive: When `true`, decoding also accepts the opposite case of every
    ///     letter in `characters`. Only valid for alphabets that use a single case.
    ///   - aliases: Additional characters to accept when decoding, mapped to the value
    ///     each stands for. See ``aliases``.
    public init(
        _ characters: some Collection<UInt8>,
        caseInsensitive: Bool = false,
        aliases: [UInt8: UInt8] = [:]
    ) {
        let digits = Array(characters)
        precondition(digits.count >= 2, "An alphabet needs a radix of at least 2")
        precondition(
            digits.count <= 255,
            "An alphabet's radix cannot exceed 255 (0xFF is reserved as the not-in-alphabet sentinel)"
        )

        var table = [UInt8](repeating: Self.sentinel, count: 256)
        for (value, character) in digits.enumerated() {
            precondition(character < 0x80, "Alphabet characters must be ASCII")
            precondition(
                table[Int(character)] == Self.sentinel,
                "An alphabet must not contain duplicate characters"
            )
            table[Int(character)] = UInt8(value)
        }

        if caseInsensitive {
            for (value, character) in digits.enumerated() {
                guard let flipped = Self.caseFlipped(character) else { continue }
                precondition(
                    table[Int(flipped)] == Self.sentinel,
                    "A case-insensitive alphabet must not contain both cases of the same letter"
                )
                table[Int(flipped)] = UInt8(value)
            }
        }

        for (character, value) in aliases {
            precondition(character < 0x80, "Alias characters must be ASCII")
            precondition(Int(value) < digits.count, "An alias must map to a value within the alphabet")
            table[Int(character)] = value
        }

        // ⌊log2(radix)⌋ from the position of the radix's most significant bit.
        let floorBits = Int.bitWidth - 1 - digits.count.leadingZeroBitCount
        self.characters = digits
        self.decodingTable = table
        self.isCaseInsensitive = caseInsensitive
        self.aliases = aliases
        self.bitsPerDigitFloor = floorBits
        self.bitsPerDigitCeil = digits.count & (digits.count - 1) == 0 ? floorBits : floorBits + 1
    }

    /// Builds an alphabet from an ASCII `String` of its digits, in value order.
    public init(
        _ characters: String,
        caseInsensitive: Bool = false,
        aliases: [UInt8: UInt8] = [:]
    ) {
        self.init(Array(characters.utf8), caseInsensitive: caseInsensitive, aliases: aliases)
    }

    // MARK: - Lookups

    /// The character that renders `value`.
    ///
    /// - Precondition: `value` is less than ``radix``.
    @inlinable
    public func character(encoding value: UInt8) -> UInt8 {
        characters[Int(value)]
    }

    /// The value that `character` stands for.
    @inlinable
    public func value(decoding character: UInt8) throws(BasesError) -> UInt8 {
        let value = decodingTable[Int(character)]
        guard value != Self.sentinel else { throw BasesError.nonAlphabetCharacter }
        return value
    }

    /// Whether `character` can be decoded by this alphabet.
    @inlinable
    public func contains(_ character: UInt8) -> Bool {
        decodingTable[Int(character)] != Self.sentinel
    }

    // MARK: - Case

    /// The same alphabet with its letters uppercased.
    public func uppercased() -> Alphabet {
        Alphabet(
            characters.map { $0 >= 0x61 && $0 <= 0x7A ? $0 - 32 : $0 },
            caseInsensitive: isCaseInsensitive,
            aliases: aliases
        )
    }

    /// The same alphabet with its letters lowercased.
    public func lowercased() -> Alphabet {
        Alphabet(
            characters.map { $0 >= 0x41 && $0 <= 0x5A ? $0 + 32 : $0 },
            caseInsensitive: isCaseInsensitive,
            aliases: aliases
        )
    }

    private static func caseFlipped(_ character: UInt8) -> UInt8? {
        switch character {
        case 0x41...0x5A: character + 32  // 'A'-'Z'
        case 0x61...0x7A: character - 32  // 'a'-'z'
        default: nil
        }
    }

    // MARK: - Sizing

    /// An upper bound on the number of digits `count` bytes encode to.
    ///
    /// Used to size the working buffer of the positional (`BaseX`) encoders up front.
    /// Derived from `⌊log2(radix)⌋`, so it over-estimates for a non-power-of-two radix
    /// rather than risking a re-allocation mid-conversion.
    public func maximumDigitCount(forByteCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (count * 8 + bitsPerDigitFloor - 1) / bitsPerDigitFloor + 1
    }

    /// An upper bound on the number of bytes `count` digits decode to.
    public func maximumByteCount(forDigitCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (count * bitsPerDigitCeil + 7) / 8 + 1
    }
}
