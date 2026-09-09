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

/// Base2 (binary) encoding — one character per bit, most significant bit first.
///
/// ```swift
/// Base2.encodedString([0x01])                  // "00000001"
/// Base2.encodedString([0x01], byteSpacing: true)
/// try Base2.decode("00000001")                 // [0x01]
/// ```
public enum Base2 {

    /// The base2 alphabet, `0` and `1`.
    public static let alphabet = Alphabet("01")

    /// The character that separates octets when `byteSpacing` is requested.
    private static let spaceCharacter: UInt8 = 0x20

    /// The number of characters that represent one byte.
    private static let charactersPerByte = 8

    // MARK: - Encoding

    /// Encodes bytes as base2 characters, most significant bit first.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to encode.
    ///   - byteSpacing: When `true`, octets are separated by a single space.
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(_ bytes: some Collection<UInt8>, byteSpacing: Bool = false) -> [UInt8] {
        withByteBuffer(bytes) { encodeCore($0, byteSpacing: byteSpacing) }
    }

    private static func encodeCore(_ bytes: UnsafeBufferPointer<UInt8>, byteSpacing: Bool) -> [UInt8] {
        let byteCount = bytes.count
        guard byteCount > 0 else { return [] }

        let stride = byteSpacing ? charactersPerByte + 1 : charactersPerByte
        let characterCount = byteCount * stride - (byteSpacing ? 1 : 0)

        let zero = alphabet.character(encoding: 0)
        let one = alphabet.character(encoding: 1)

        return [UInt8](unsafeUninitializedCapacity: characterCount) { characters, initializedCount in
            var offset = 0
            for byte in bytes {
                if byteSpacing && offset > 0 {
                    characters[offset] = spaceCharacter
                    offset += 1
                }
                var mask: UInt8 = 0b1000_0000
                for _ in 0..<charactersPerByte {
                    characters[offset] = byte & mask == 0 ? zero : one
                    mask >>= 1
                    offset += 1
                }
            }
            initializedCount = characterCount
        }
    }

    /// Encodes bytes as a base2 `String`, most significant bit first.
    public static func encodedString(_ bytes: some Collection<UInt8>, byteSpacing: Bool = false) -> String {
        String(decoding: encode(bytes, byteSpacing: byteSpacing), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes base2 characters into bytes.
    ///
    /// Spaces are ignored wherever they appear, so both the spaced and unspaced forms
    /// produced by ``encode(_:byteSpacing:)`` decode.
    ///
    /// - Throws:
    ///   - ``BasesError/nonAlphabetCharacter`` for a character other than `0`, `1` or a space
    ///   - ``BasesError/invalidLength`` if the bits do not fill whole bytes.
    public static func decode(_ characters: some Collection<UInt8>) throws(BasesError) -> [UInt8] {
        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / charactersPerByte + 1)

        var accumulator: UInt8 = 0
        var bits = 0
        for character in characters {
            if character == spaceCharacter { continue }
            let bit = try alphabet.value(decoding: character)
            accumulator = accumulator << 1 | bit
            bits += 1
            if bits == charactersPerByte {
                bytes.append(accumulator)
                accumulator = 0
                bits = 0
            }
        }
        guard bits == 0 else { throw BasesError.invalidLength }
        return bytes
    }

    /// Decodes a base2 `String` into bytes.
    public static func decode(_ string: some StringProtocol) throws(BasesError) -> [UInt8] {
        try decode(string.utf8)
    }
}

extension Collection<UInt8> {
    /// Renders these bytes as a base2 `String`, most significant bit first.
    ///
    /// ```swift
    /// [UInt8]([1]).binaryEncoded()  // "00000001"
    /// ```
    public func binaryEncoded(byteSpacing: Bool = false) -> String {
        Base2.encodedString(self, byteSpacing: byteSpacing)
    }
}
