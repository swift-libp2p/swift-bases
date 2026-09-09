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

/// Base8 (octal) encoding, three bytes become eight characters, padded with `=`.
///
/// ```swift
/// Base8.encodedString(Array("hi libp2p!".utf8), pad: .unpadded)  // "320644403306454234031160102"
/// try Base8.decode("320644403306454234031160102")
/// ```
public enum Base8 {

    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 3
    /// The size of a block after encoding, measured in characters.
    private static let encodedBlockSize = 8

    // MARK: - Encoding

    /// Encodes bytes as base8 characters.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to encode.
    ///   - pad: Whether to pad the final block out to eight characters with `=`.
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(_ bytes: some Collection<UInt8>, pad: PadOption = .padded) -> [UInt8] {
        let unencodedByteCount = bytes.count
        guard unencodedByteCount > 0 else { return [] }

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

    /// Encodes bytes as a base8 `String`.
    public static func encodedString(_ bytes: some Collection<UInt8>, pad: PadOption = .padded) -> String {
        String(decoding: encode(bytes, pad: pad), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes base8 characters into bytes.
    ///
    /// Trailing `=` padding is optional, so both the padded and unpadded forms produced by
    /// ``encode(_:pad:)`` decode.
    ///
    /// - Throws:
    ///   - ``BasesError/nonAlphabetCharacter`` for a character outside `0`-`7`.
    ///   - ``BasesError/incompleteBlock`` if the final block holds an impossible number of characters.
    ///   - ``BasesError/strayBits`` if its unused bits are not zero.
    public static func decode(_ characters: some Collection<UInt8>) throws(BasesError) -> [UInt8] {
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
            // Padding only ever terminates the input, a character after it is malformed.
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
                filled = 0
            }
        }

        switch filled {
        case 0:
            break
        case 3:
            bytes.append(try decodeBlock(block[0], block[1], block[2], using: alphabet))
        case 6:
            let decoded = try decodeBlock(
                block[0],
                block[1],
                block[2],
                block[3],
                block[4],
                block[5],
                using: alphabet
            )
            bytes.append(decoded.0)
            bytes.append(decoded.1)
        default:
            throw BasesError.incompleteBlock
        }
        return bytes
    }

    /// Decodes a base8 `String` into bytes.
    public static func decode(_ string: some StringProtocol) throws(BasesError) -> [UInt8] {
        try decode(string.utf8)
    }

    // MARK: - Sizing

    /// The number of significant characters a partial block of `byteCount` bytes produces.
    private static func characterCount(encoding byteCount: Int) -> Int {
        switch byteCount {
        case 1: 3
        case 2: 6
        default: encodedBlockSize
        }
    }
}
