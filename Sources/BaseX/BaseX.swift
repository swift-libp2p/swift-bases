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
        if base.isHex {
            return hexEncode(bytes, using: base.alphabet)
        }
        return positionalEncode(bytes, using: base.alphabet)
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
        if base.isHex {
            return try hexDecode(characters, using: base.alphabet)
        }
        return try positionalDecode(characters, using: base.alphabet)
    }

    /// Decodes a `String` in the given alphabet into bytes.
    public static func decode(
        _ string: some StringProtocol,
        as base: Alphabets
    ) throws(BasesError) -> [UInt8] {
        try decode(string.utf8, as: base)
    }

    // MARK: - The general positional path

    private static func positionalEncode(_ bytes: some Collection<UInt8>, using alphabet: Alphabet) -> [UInt8] {
        guard !bytes.isEmpty else { return [] }
        let radix = UInt(alphabet.radix)

        // Leading zero bytes carry no value in a positional encoding, so they are counted
        // out and re-added as leading zero digits afterwards.
        let zeros = bytes.prefix(while: { $0 == 0 }).count
        let significant = bytes.dropFirst(zeros)

        // Sized from ⌊log2(radix)⌋ up front, so the conversion never re-allocates.
        // The buffer holds the digits big-endian, right-aligned.
        let size = alphabet.maximumDigitCount(forByteCount: significant.count)
        var digits = [UInt8](repeating: 0, count: size)
        var length = 0
        for byte in significant {
            var carry = UInt(byte)
            var written = 0
            var index = size - 1
            while carry != 0 || written < length {
                carry += 256 * UInt(digits[index])
                digits[index] = UInt8(carry % radix)
                carry /= radix
                written += 1
                index -= 1
            }
            length = written
        }

        var characters = [UInt8]()
        characters.reserveCapacity(zeros + length)
        characters.append(contentsOf: repeatElement(alphabet.leader, count: zeros))
        for index in (size - length)..<size {
            characters.append(alphabet.character(encoding: digits[index]))
        }
        return characters
    }

    private static func positionalDecode(
        _ characters: some Collection<UInt8>,
        using alphabet: Alphabet
    ) throws(BasesError) -> [UInt8] {
        guard !characters.isEmpty else { return [] }
        let radix = UInt(alphabet.radix)
        let leader = alphabet.leader

        let zeros = characters.prefix(while: { $0 == leader }).count
        let significant = characters.dropFirst(zeros)

        let size = alphabet.maximumByteCount(forDigitCount: significant.count)
        var buffer = [UInt8](repeating: 0, count: size)
        var length = 0
        for character in significant {
            var carry = UInt(try alphabet.value(decoding: character))
            var written = 0
            var index = size - 1
            while carry != 0 || written < length {
                carry += radix * UInt(buffer[index])
                buffer[index] = UInt8(carry & 0xFF)
                carry >>= 8
                written += 1
                index -= 1
            }
            length = written
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(zeros + length)
        bytes.append(contentsOf: repeatElement(0, count: zeros))
        bytes.append(contentsOf: buffer[(size - length)..<size])
        return bytes
    }

    // MARK: - The base16 fast path
    //
    // Base16 needs no big-number arithmetic, every byte is exactly two digits. Routing it
    // through the positional path made encoding and decoding quadratic, a 4KB payload took
    // over seven seconds. See `BaseXPerformance`.

    private static func hexEncode(_ bytes: some Collection<UInt8>, using alphabet: Alphabet) -> [UInt8] {
        var characters = [UInt8](repeating: 0, count: bytes.count * 2)
        var offset = 0
        for byte in bytes {
            characters[offset] = alphabet.character(encoding: byte >> 4)
            characters[offset + 1] = alphabet.character(encoding: byte & 0x0F)
            offset += 2
        }
        return characters
    }

    private static func hexDecode(
        _ characters: some Collection<UInt8>,
        using alphabet: Alphabet
    ) throws(BasesError) -> [UInt8] {
        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / 2 + 1)

        var index = characters.startIndex
        // Tolerate a "0x" prefix, as the pre-0.4.0 parser did.
        if characters.count >= 2 {
            let second = characters.index(after: index)
            if characters[index] == UInt8(ascii: "0") && characters[second] == UInt8(ascii: "x") {
                index = characters.index(after: second)
            }
        }

        var high: UInt8? = nil
        while index != characters.endIndex {
            let nibble = try alphabet.value(decoding: characters[index])
            if let first = high {
                bytes.append(first << 4 | nibble)
                high = nil
            } else {
                high = nibble
            }
            index = characters.index(after: index)
        }
        // A leftover nibble means an odd number of hex digits.
        guard high == nil else { throw BasesError.invalidLength }
        return bytes
    }
}
