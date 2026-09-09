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

@_exported import BasesCore

/// Base64 encoding/decoding covering the four variants defined by the multibase spec.
///
/// The single-character multibase prefix (`m`, `M`, `u`, `U`) is *not* handled here, that
/// belongs to the multibase layer. This type produces/consumes the raw base64 payload for:
///
/// ```
/// | multibase | variant     | padded |
/// |-----------|-------------|--------|
/// | `m`       | `.standard` | `false`|
/// | `M`       | `.standard` | `true` |
/// | `u`       | `.url`      | `false`|
/// | `U`       | `.url`      | `true` |
/// ```
///
/// Decoding is padding-agnostic, it accepts input with or without trailing `=`, so the
/// unpadded (`m`/`u`) forms round-trip correctly.
public enum Base64 {

    /// Which base64 alphabet to use.
    public enum Variant: Sendable {

        /// Standard RFC 4648 alphabet using `+` and `/` (multibase `m` / `M`).
        case standard

        /// URL (and filename) safe alphabet using `-` and `_` (multibase `u` / `U`).
        case url

        /// This variant's alphabet.
        ///
        /// - Note: ``url`` also *decodes* `+` and `/`, which keeps the pre-0.4.0 behavior
        ///   where URL-safe input was rewritten into the standard alphabet before being
        ///   handed to Foundation. Encoding only ever emits `-` and `_`.
        public var alphabet: Alphabet {
            switch self {
            case .standard: Alphabets.standard
            case .url: Alphabets.url
            }
        }
    }

    /// The cached base64 alphabets.
    internal enum Alphabets {
        static let standard = Alphabet(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        )
        static let url = Alphabet(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
            aliases: [UInt8(ascii: "+"): 62, UInt8(ascii: "/"): 63]
        )
    }

    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 3

    /// The size of a block after encoding, measured in characters.
    private static let encodedBlockSize = 4

    // MARK: - Encoding

    /// Encodes bytes as base64 characters in the given variant.
    ///
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        pad: PadOption = .padded
    ) -> [UInt8] {
        withByteBuffer(bytes) { encodeCore($0, variant: variant, pad: pad) }
    }

    private static func encodeCore(
        _ bytes: UnsafeBufferPointer<UInt8>,
        variant: Variant,
        pad: PadOption
    ) -> [UInt8] {
        let unencodedByteCount = bytes.count
        guard unencodedByteCount > 0 else { return [] }

        let blockCount = (unencodedByteCount + unencodedBlockSize - 1) / unencodedBlockSize
        let remainder = unencodedByteCount % unencodedBlockSize
        // The padded length is always a whole number of blocks. Unpadded, a 1-byte tail is
        // two characters and a 2-byte tail is three, reported as the initialized count, so
        // the padding written past it is simply left out of the array.
        let characterCount =
            pad == .padded || remainder == 0
            ? blockCount * encodedBlockSize
            : (blockCount - 1) * encodedBlockSize + remainder + 1

        return variant.alphabet.withEncodingTable { table in
            [UInt8](unsafeUninitializedCapacity: blockCount * encodedBlockSize) { characters, initializedCount in
                var readOffset = 0
                var writeOffset = 0
                while readOffset + unencodedBlockSize <= unencodedByteCount {
                    let bits =
                        UInt32(bytes[readOffset]) << 16
                        | UInt32(bytes[readOffset + 1]) << 8
                        | UInt32(bytes[readOffset + 2])
                    characters[writeOffset + 0] = table[Int(bits >> 18 & 0x3F)]
                    characters[writeOffset + 1] = table[Int(bits >> 12 & 0x3F)]
                    characters[writeOffset + 2] = table[Int(bits >> 6 & 0x3F)]
                    characters[writeOffset + 3] = table[Int(bits & 0x3F)]
                    readOffset += unencodedBlockSize
                    writeOffset += encodedBlockSize
                }

                switch remainder {
                case 1:
                    // 8 bits become two characters, the second carries 2 zero bits.
                    let bits = UInt32(bytes[readOffset]) << 16
                    characters[writeOffset + 0] = table[Int(bits >> 18 & 0x3F)]
                    characters[writeOffset + 1] = table[Int(bits >> 12 & 0x3F)]
                    characters[writeOffset + 2] = Alphabet.paddingCharacter
                    characters[writeOffset + 3] = Alphabet.paddingCharacter
                case 2:
                    // 16 bits become three characters, the third carries 4 zero bits.
                    let bits = UInt32(bytes[readOffset]) << 16 | UInt32(bytes[readOffset + 1]) << 8
                    characters[writeOffset + 0] = table[Int(bits >> 18 & 0x3F)]
                    characters[writeOffset + 1] = table[Int(bits >> 12 & 0x3F)]
                    characters[writeOffset + 2] = table[Int(bits >> 6 & 0x3F)]
                    characters[writeOffset + 3] = Alphabet.paddingCharacter
                default:
                    break
                }
                initializedCount = characterCount
            }
        }
    }

    /// Encodes bytes as a base64 `String` in the given variant.
    public static func encodedString(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        pad: PadOption = .padded
    ) -> String {
        String(decoding: encode(bytes, variant: variant, pad: pad), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes base64 characters (padded or unpadded) in the given variant into bytes.
    ///
    /// - Throws:
    ///   - ``BasesError/nonAlphabetCharacter`` for a character outside the variant's alphabet
    ///   - ``BasesError/incompleteBlock`` if the final block holds a single character,
    ///     which no byte could have produced.
    ///
    /// - Note: Lenient about the unused low bits of a partial final block, matching the
    ///   behavior of the Foundation decoder this replaces.
    public static func decode(
        _ characters: some Collection<UInt8>,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(characters, { decodeCore($0, variant: variant) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    private static func decodeCore(
        _ characters: UnsafeBufferPointer<UInt8>,
        variant: Variant
    ) -> Result<[UInt8], BasesError> {
        // Trailing padding is optional, so find where the significant characters end.
        // A `=` anywhere before that is not in the alphabet and is rejected below, which is
        // how data after the padding is caught.
        var encodedCount = characters.count
        while encodedCount > 0 && characters[encodedCount - 1] == Alphabet.paddingCharacter {
            encodedCount -= 1
        }
        guard encodedCount > 0 else { return .success([]) }

        // This is an upper bound, the last block may be partial. The exact count is
        // reported back as the initialized count once the blocks have been decoded.
        let capacity = encodedCount / encodedBlockSize * unencodedBlockSize + unencodedBlockSize

        return variant.alphabet.withDecodingTable { table in
            var failure: BasesError? = nil
            let bytes = [UInt8](unsafeUninitializedCapacity: capacity) { bytes, initializedCount in
                var readOffset = 0
                var writeOffset = 0

                while readOffset + encodedBlockSize <= encodedCount {
                    let v0 = table[Int(characters[readOffset])]
                    let v1 = table[Int(characters[readOffset + 1])]
                    let v2 = table[Int(characters[readOffset + 2])]
                    let v3 = table[Int(characters[readOffset + 3])]
                    // Every value in the alphabet is < 64 and the sentinel is 0xFF, so one
                    // comparison rejects any of the four characters.
                    guard (v0 | v1 | v2 | v3) < 0x40 else {
                        failure = .nonAlphabetCharacter
                        break
                    }
                    let bits = UInt32(v0) << 18 | UInt32(v1) << 12 | UInt32(v2) << 6 | UInt32(v3)
                    bytes[writeOffset + 0] = UInt8(truncatingIfNeeded: bits >> 16)
                    bytes[writeOffset + 1] = UInt8(truncatingIfNeeded: bits >> 8)
                    bytes[writeOffset + 2] = UInt8(truncatingIfNeeded: bits)
                    readOffset += encodedBlockSize
                    writeOffset += unencodedBlockSize
                }

                if failure == nil, readOffset < encodedCount {
                    let tail = encodedCount - readOffset
                    var bits: UInt32 = 0
                    for offset in 0..<tail {
                        let value = table[Int(characters[readOffset + offset])]
                        if value == Alphabet.sentinel {
                            failure = .nonAlphabetCharacter
                            break
                        }
                        bits = bits << 6 | UInt32(value)
                    }
                    if failure == nil {
                        switch tail {
                        case 2:
                            // 12 bits carry one byte; the low 4 are unused.
                            bytes[writeOffset] = UInt8(truncatingIfNeeded: bits >> 4)
                            writeOffset += 1
                        case 3:
                            // 18 bits carry two bytes; the low 2 are unused.
                            bytes[writeOffset + 0] = UInt8(truncatingIfNeeded: bits >> 10)
                            bytes[writeOffset + 1] = UInt8(truncatingIfNeeded: bits >> 2)
                            writeOffset += 2
                        default:
                            // A single trailing character carries 6 bits, fewer than a byte.
                            failure = .incompleteBlock
                        }
                    }
                }
                initializedCount = writeOffset
            }
            if let failure { return .failure(failure) }
            return .success(bytes)
        }
    }

    /// Decodes a base64 `String` (padded or unpadded) in the given variant into bytes.
    public static func decode(
        _ string: some StringProtocol,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(string, { decodeCore($0, variant: variant) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }
}
