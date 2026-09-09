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
        let length = digits.withUnsafeMutableBufferPointer {
            convert(bytes: bytes, from: zeros, into: $0, radix: radix)
        }

        let digitCount = zeros + length
        return alphabet.withEncodingTable { table in
            digits.withUnsafeBufferPointer { digits in
                [UInt8](unsafeUninitializedCapacity: digitCount) { characters, initializedCount in
                    if zeros > 0 {
                        characters.baseAddress!.update(repeating: table[0], count: zeros)
                    }
                    for offset in 0..<length {
                        characters[zeros + offset] = table[Int(digits[size - length + offset])]
                    }
                    initializedCount = digitCount
                }
            }
        }
    }

    /// Converts `bytes[start...]` from base 256 into `digits`, in the alphabet's radix,
    /// big-endian and right-aligned in the buffer.
    ///
    /// - Returns: The number of significant digits written, at the buffer's right edge.
    private static func convert(
        bytes: UnsafeBufferPointer<UInt8>,
        from start: Int,
        into digits: UnsafeMutableBufferPointer<UInt8>,
        radix: UInt
    ) -> Int {
        let size = digits.count
        var length = 0
        for index in start..<bytes.count {
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
        return length
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
        let converted = alphabet.withDecodingTable { table in
            buffer.withUnsafeMutableBufferPointer {
                convert(characters: characters, from: zeros, into: $0, radix: radix, table: table)
            }
        }
        guard let length = converted else { return .failure(.nonAlphabetCharacter) }

        let byteCount = zeros + length
        return .success(
            buffer.withUnsafeBufferPointer { buffer in
                [UInt8](unsafeUninitializedCapacity: byteCount) { bytes, initializedCount in
                    if zeros > 0 {
                        bytes.baseAddress!.update(repeating: 0, count: zeros)
                    }
                    if length > 0 {
                        // The significant bytes are already contiguous, so this is a memcpy.
                        (bytes.baseAddress! + zeros).update(
                            from: buffer.baseAddress! + (size - length),
                            count: length
                        )
                    }
                    initializedCount = byteCount
                }
            }
        )
    }

    /// Converts `characters[start...]` from the alphabet's radix into `bytes`, base 256,
    /// big-endian and right-aligned in the buffer.
    ///
    /// - Returns: The number of significant bytes written, at the buffer's right edge, or
    ///   `nil` if a character was not in the alphabet.
    private static func convert(
        characters: UnsafeBufferPointer<UInt8>,
        from start: Int,
        into bytes: UnsafeMutableBufferPointer<UInt8>,
        radix: UInt,
        table: UnsafeBufferPointer<UInt8>
    ) -> Int? {
        let size = bytes.count
        var length = 0
        for index in start..<characters.count {
            let value = table[Int(characters[index])]
            guard value != Alphabet.sentinel else { return nil }
            var carry = UInt(value)
            var written = 0
            var position = size - 1
            while carry != 0 || written < length {
                carry += radix * UInt(bytes[position])
                bytes[position] = UInt8(carry & 0xFF)
                carry >>= 8
                written += 1
                position -= 1
            }
            length = written
        }
        return length
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
            let end = characters.count
            var failure: BasesError? = nil
            let bytes = [UInt8](unsafeUninitializedCapacity: digitCount / 2) { bytes, initializedCount in
                // Operate on a pair of digits in a single pass.
                var index = start
                var writeOffset = 0
                while index + 1 < end {
                    let high = table[Int(characters[index])]
                    let low = table[Int(characters[index + 1])]
                    // Every hex value is < 16 and the sentinel is 0xFF, so one comparison
                    // rejects either character.
                    guard (high | low) < 0x10 else {
                        failure = .nonAlphabetCharacter
                        break
                    }
                    bytes[writeOffset] = high << 4 | low
                    writeOffset += 1
                    index += 2
                }
                initializedCount = writeOffset

                // An odd number of digits leaves one behind. Report a bad character in
                // preference to the length, matching the order the per-character loop
                // reported them in.
                if failure == nil, index < end {
                    failure =
                        table[Int(characters[index])] == Alphabet.sentinel
                        ? .nonAlphabetCharacter
                        : .invalidLength
                }
            }
            if let failure { return .failure(failure) }
            return .success(bytes)
        }
    }
}
