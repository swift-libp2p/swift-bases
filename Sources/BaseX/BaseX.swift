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

/// Positional base conversion for base10, base16, base36, base58 and any
/// custom alphabet.
///
/// Unlike the block encodings, these bases treat the input as one big-endian integer, so a
/// leading zero byte carries no value of its own. Following the convention base58 set, each
/// leading zero byte is rendered as one leading zero *digit* and restored on the way back.
///
/// ```swift
/// BaseX.encodedString(Array("hi libp2p!".utf8), into: .base58BTC)  // "6sEA5mWp2H4r4x"
/// try BaseX.decode("6sEA5mWp2H4r4x", as: .base58BTC)
/// ```
public enum BaseX {

    // MARK: - Encoding

    /// Encodes bytes into the given alphabet.
    ///
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(_ bytes: some Collection<UInt8>, into base: Alphabets) -> [UInt8] {
        let alphabet = base.alphabet
        if base.isHex {
            return withByteBuffer(bytes) { hexEncode($0, using: alphabet) }
        }
        return withByteBuffer(bytes) { positionalEncode($0, using: alphabet) }
    }

    /// Encodes bytes into the given alphabet as a `String`.
    public static func encodedString(_ bytes: some Collection<UInt8>, into base: Alphabets) -> String {
        String(decoding: encode(bytes, into: base), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes characters in the given alphabet into bytes.
    ///
    /// - Throws:
    ///    - ``BasesError/nonAlphabetCharacter`` for a character outside the alphabet.
    ///    - ``BasesError/invalidLength`` if a base16 input holds an odd number of digits,
    ///      since a dangling nibble is not a whole byte.
    public static func decode(
        _ characters: some Collection<UInt8>,
        as base: Alphabets
    ) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(characters, { decodeCore($0, as: base) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    /// Decodes a `String` in the given alphabet into bytes.
    public static func decode(
        _ string: some StringProtocol,
        as base: Alphabets
    ) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(string, { decodeCore($0, as: base) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    /// The decoding entry point.
    ///
    /// Returns a `Result` rather than throwing because it runs inside the non-throwing
    /// closure `withByteBuffer(_:_:)` requires. See that function's note.
    private static func decodeCore(
        _ characters: UnsafeBufferPointer<UInt8>,
        as base: Alphabets
    ) -> Result<[UInt8], BasesError> {
        let alphabet = base.alphabet
        if base.isHex {
            return hexDecode(characters, using: alphabet)
        }
        return positionalDecode(characters, using: alphabet)
    }

    // MARK: - The general positional path

    private static func positionalEncode(
        _ bytes: UnsafeBufferPointer<UInt8>,
        using alphabet: Alphabet
    ) -> [UInt8] {
        let byteCount = bytes.count
        guard byteCount > 0 else { return [] }
        let radix = UInt(alphabet.radix)

        // Leading zero bytes carry no value in a positional encoding, so they are counted
        // out and re-added as leading zero digits afterwards.
        var zeros = 0
        while zeros < byteCount && bytes[zeros] == 0 { zeros += 1 }

        // Sized from ⌊log2(radix)⌋ up front, so the conversion never re-allocates.
        // The buffer holds the digits big-endian, right-aligned.
        let size = alphabet.maximumDigitCount(forByteCount: byteCount - zeros)
        var digits = [UInt8](repeating: 0, count: size)
        var length = 0
        digits.withUnsafeMutableBufferPointer { digits in
            for index in zeros..<byteCount {
                var carry = UInt(bytes[index])
                var written = 0
                var position = size - 1
                while carry != 0 || written < length {
                    carry += 256 * UInt(digits[position])
                    digits[position] = UInt8(carry % radix)
                    carry /= radix
                    written += 1
                    position -= 1
                }
                length = written
            }
        }

        let digitCount = zeros + length
        return alphabet.withEncodingTable { table in
            digits.withUnsafeBufferPointer { digits in
                [UInt8](unsafeUninitializedCapacity: digitCount) { characters, initializedCount in
                    let leader = table[0]
                    for offset in 0..<zeros { characters[offset] = leader }
                    for offset in 0..<length {
                        characters[zeros + offset] = table[Int(digits[size - length + offset])]
                    }
                    initializedCount = digitCount
                }
            }
        }
    }

    private static func positionalDecode(
        _ characters: UnsafeBufferPointer<UInt8>,
        using alphabet: Alphabet
    ) -> Result<[UInt8], BasesError> {
        let characterCount = characters.count
        guard characterCount > 0 else { return .success([]) }
        let radix = UInt(alphabet.radix)
        let leader = alphabet.leader

        var zeros = 0
        while zeros < characterCount && characters[zeros] == leader { zeros += 1 }

        let size = alphabet.maximumByteCount(forDigitCount: characterCount - zeros)
        var buffer = [UInt8](repeating: 0, count: size)
        var length = 0

        let failure: BasesError? = alphabet.withDecodingTable { table in
            buffer.withUnsafeMutableBufferPointer { buffer -> BasesError? in
                for index in zeros..<characterCount {
                    let value = table[Int(characters[index])]
                    guard value != Alphabet.sentinel else { return .nonAlphabetCharacter }
                    var carry = UInt(value)
                    var written = 0
                    var position = size - 1
                    while carry != 0 || written < length {
                        carry += radix * UInt(buffer[position])
                        buffer[position] = UInt8(carry & 0xFF)
                        carry >>= 8
                        written += 1
                        position -= 1
                    }
                    length = written
                }
                return nil
            }
        }
        if let failure { return .failure(failure) }

        let byteCount = zeros + length
        return .success(
            buffer.withUnsafeBufferPointer { buffer in
                [UInt8](unsafeUninitializedCapacity: byteCount) { bytes, initializedCount in
                    for offset in 0..<zeros { bytes[offset] = 0 }
                    for offset in 0..<length { bytes[zeros + offset] = buffer[size - length + offset] }
                    initializedCount = byteCount
                }
            }
        )
    }

    // MARK: - The base16 fast path
    //
    // Base16 needs no big-number arithmetic, every byte is exactly two digits. Routing it
    // through the positional path made encoding and decoding quadratic, a 4KB payload took
    // over seven seconds. See `BaseXPerformance`.

    private static func hexEncode(_ bytes: UnsafeBufferPointer<UInt8>, using alphabet: Alphabet) -> [UInt8] {
        let byteCount = bytes.count
        guard byteCount > 0 else { return [] }
        return alphabet.withEncodingTable { table in
            [UInt8](unsafeUninitializedCapacity: byteCount * 2) { characters, initializedCount in
                var offset = 0
                for byte in bytes {
                    characters[offset] = table[Int(byte >> 4)]
                    characters[offset + 1] = table[Int(byte & 0x0F)]
                    offset += 2
                }
                initializedCount = byteCount * 2
            }
        }
    }

    private static func hexDecode(
        _ characters: UnsafeBufferPointer<UInt8>,
        using alphabet: Alphabet
    ) -> Result<[UInt8], BasesError> {
        // Tolerate a "0x" prefix, as the pre-0.4.0 parser did.
        var start = 0
        if characters.count >= 2, characters[0] == UInt8(ascii: "0"), characters[1] == UInt8(ascii: "x") {
            start = 2
        }
        let digitCount = characters.count - start
        guard digitCount > 0 else { return .success([]) }

        return alphabet.withDecodingTable { table in
            var failure: BasesError? = nil
            let bytes = [UInt8](unsafeUninitializedCapacity: digitCount / 2) { bytes, initializedCount in
                var writeOffset = 0
                var high: UInt8? = nil
                for index in start..<characters.count {
                    let nibble = table[Int(characters[index])]
                    guard nibble != Alphabet.sentinel else {
                        failure = .nonAlphabetCharacter
                        break
                    }
                    if let first = high {
                        bytes[writeOffset] = first << 4 | nibble
                        writeOffset += 1
                        high = nil
                    } else {
                        high = nibble
                    }
                }
                // A leftover nibble means an odd number of hex digits.
                if failure == nil && high != nil { failure = .invalidLength }
                initializedCount = writeOffset
            }
            if let failure { return .failure(failure) }
            return .success(bytes)
        }
    }
}
