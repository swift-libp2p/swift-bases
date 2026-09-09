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

//
//  Base32.swift
//  Bases
//
//  Copyright (c) 2015-2019 Matt Rubin and the Bases authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@_exported import BasesCore

/// Base32 encoding, five bytes become eight characters, padded with `=`.
///
/// Three alphabets are supported through ``Variant``:
/// - RFC 4648 base32
/// - RFC 4648 "extended hex" base32
/// - z-base-32
///
/// ```swift
/// Base32.encodedString(Array("hi libp2p!".utf8), letterCase: .lower, pad: .unpadded)
/// // "nbusa3djmjyde4bb"
/// try Base32.decode("NBUSA3DJMJYDE4BB")
/// ```
public enum Base32 {

    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 5

    /// The size of a block after encoding, measured in characters.
    private static let encodedBlockSize = 8

    // MARK: - Encoding

    /// Encodes bytes as base32 characters.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to encode.
    ///   - variant: Which base32 alphabet to use.
    ///   - letterCase: The case to render letters in. Defaults to the variant's natural case
    ///     - upper for ``Variant/standard`` and ``Variant/hex``
    ///     - lower for ``Variant/z``.
    ///   - pad: Whether to pad the final block out to eight characters with `=`.
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        letterCase: LetterCase? = nil,
        pad: PadOption = .padded
    ) -> [UInt8] {
        let unencodedByteCount = bytes.count
        guard unencodedByteCount > 0 else { return [] }

        let alphabet = variant.alphabet(letterCase)
        let blockCount = (unencodedByteCount + unencodedBlockSize - 1) / unencodedBlockSize
        var characters = [EncodedChar](repeating: paddingCharacter, count: blockCount * encodedBlockSize)

        var block = [Byte](repeating: 0, count: unencodedBlockSize)
        var filled = 0
        var offset = 0
        for byte in bytes {
            block[filled] = byte
            filled += 1
            if filled == unencodedBlockSize {
                write(encodeBlock(block, count: filled, using: alphabet), into: &characters, at: offset)
                offset += encodedBlockSize
                filled = 0
            }
        }
        if filled > 0 {
            write(encodeBlock(block, count: filled, using: alphabet), into: &characters, at: offset)
            if pad == .unpadded {
                characters.removeLast(encodedBlockSize - characterCount(encoding: filled))
            }
        }
        return characters
    }

    /// Encodes bytes as a base32 `String`.
    public static func encodedString(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        letterCase: LetterCase? = nil,
        pad: PadOption = .padded
    ) -> String {
        String(decoding: encode(bytes, variant: variant, letterCase: letterCase, pad: pad), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes base32 characters into bytes.
    ///
    /// Decoding is case-insensitive and trailing `=` padding is optional, so every form that
    /// ``encode(_:variant:letterCase:pad:)`` produces, decodes.
    ///
    /// - Throws:
    ///   - ``BasesError/nonAlphabetCharacter`` for a character outside the variant's alphabet.
    ///   - ``BasesError/incompleteBlock`` if the final block holds an invalid number of characters.
    ///   - ``BasesError/strayBits`` if its unused bits are not zero.
    public static func decode(
        _ characters: some Collection<UInt8>,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        let alphabet = variant.decodingAlphabet
        var bytes = [Byte]()
        bytes.reserveCapacity(characters.count / encodedBlockSize * unencodedBlockSize + unencodedBlockSize)

        var block = [EncodedChar](repeating: 0, count: encodedBlockSize)
        var filled = 0
        var sawPadding = false
        for character in characters {
            if character == paddingCharacter {
                sawPadding = true
                continue
            }
            // Padding only ever terminates the input; a character after it is malformed.
            guard !sawPadding else { throw BasesError.nonAlphabetCharacter }
            block[filled] = character
            filled += 1
            if filled == encodedBlockSize {
                let decoded = try decodeBlock(
                    block[0],
                    block[1],
                    block[2],
                    block[3],
                    block[4],
                    block[5],
                    block[6],
                    block[7],
                    using: alphabet
                )
                bytes.append(decoded.0)
                bytes.append(decoded.1)
                bytes.append(decoded.2)
                bytes.append(decoded.3)
                bytes.append(decoded.4)
                filled = 0
            }
        }

        switch filled {
        case 0:
            break
        case 2:
            bytes.append(try decodeBlock(block[0], block[1], using: alphabet))
        case 4:
            let decoded = try decodeBlock(block[0], block[1], block[2], block[3], using: alphabet)
            bytes.append(decoded.0)
            bytes.append(decoded.1)
        case 5:
            let decoded = try decodeBlock(block[0], block[1], block[2], block[3], block[4], using: alphabet)
            bytes.append(decoded.0)
            bytes.append(decoded.1)
            bytes.append(decoded.2)
        case 7:
            let decoded = try decodeBlock(
                block[0],
                block[1],
                block[2],
                block[3],
                block[4],
                block[5],
                block[6],
                using: alphabet
            )
            bytes.append(decoded.0)
            bytes.append(decoded.1)
            bytes.append(decoded.2)
            bytes.append(decoded.3)
        default:
            throw BasesError.incompleteBlock
        }
        return bytes
    }

    /// Decodes a base32 `String` into bytes.
    public static func decode(
        _ string: some StringProtocol,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        try decode(string.utf8, variant: variant)
    }

    // MARK: - Sizing

    /// The number of significant characters a partial block of `byteCount` bytes produces.
    private static func characterCount(encoding byteCount: Int) -> Int {
        switch byteCount {
        case 1: 2
        case 2: 4
        case 3: 5
        case 4: 7
        default: encodedBlockSize
        }
    }
}
