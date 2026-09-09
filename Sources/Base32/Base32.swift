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
        withByteBuffer(bytes) { encodeCore($0, variant: variant, letterCase: letterCase, pad: pad) }
    }

    private static func encodeCore(
        _ bytes: UnsafeBufferPointer<Byte>,
        variant: Variant,
        letterCase: LetterCase?,
        pad: PadOption
    ) -> [UInt8] {
        let unencodedByteCount = bytes.count
        guard unencodedByteCount > 0 else { return [] }

        let blockCount = (unencodedByteCount + unencodedBlockSize - 1) / unencodedBlockSize
        let remainder = unencodedByteCount % unencodedBlockSize
        // The padded length is always a whole number of blocks. Unpadded, the final block
        // contributes only its significant characters, reported as the initialized count,
        // so the padding written past it is simply left out of the array.
        let characterCount =
            pad == .padded || remainder == 0
            ? blockCount * encodedBlockSize
            : (blockCount - 1) * encodedBlockSize + characterCount(encoding: remainder)

        return variant.alphabet(letterCase).withEncodingTable { table in
            [UInt8](unsafeUninitializedCapacity: blockCount * encodedBlockSize) { characters, initializedCount in
                var readOffset = 0
                var writeOffset = 0
                while readOffset < unencodedByteCount {
                    let blockSize = min(unencodedBlockSize, unencodedByteCount - readOffset)
                    write(
                        encodeBlock(bytes, at: readOffset, count: blockSize, using: table),
                        into: characters,
                        at: writeOffset
                    )
                    readOffset += blockSize
                    writeOffset += encodedBlockSize
                }
                initializedCount = characterCount
            }
        }
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
        switch withByteBuffer(characters, { decodeCore($0, variant: variant) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    /// Decodes a base32 `String` into bytes.
    public static func decode(
        _ string: some StringProtocol,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(string, { decodeCore($0, variant: variant) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    private static func decodeCore(
        _ characters: UnsafeBufferPointer<EncodedChar>,
        variant: Variant
    ) -> Result<[UInt8], BasesError> {
        // Trailing padding is optional, so find where the significant characters end.
        // A `=` anywhere before that is not in the alphabet and is rejected by the block
        // decoder, which is how data after the padding is caught.
        var encodedCount = characters.count
        while encodedCount > 0 && characters[encodedCount - 1] == paddingCharacter {
            encodedCount -= 1
        }
        guard encodedCount > 0 else { return .success([]) }

        // This is an upper bound, the last block may be partial. The exact count is
        // reported back as the initialized count once the blocks have been decoded.
        let capacity = encodedCount / encodedBlockSize * unencodedBlockSize + unencodedBlockSize

        return variant.decodingAlphabet.withDecodingTable { table in
            var failure: BasesError? = nil
            let bytes = [UInt8](unsafeUninitializedCapacity: capacity) { bytes, initializedCount in
                var readOffset = 0
                var writeOffset = 0
                blocks: while readOffset < encodedCount {
                    let blockSize = min(encodedBlockSize, encodedCount - readOffset)
                    do throws(BasesError) {
                        switch blockSize {
                        case 2:
                            bytes[writeOffset] = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                using: table
                            )
                            writeOffset += 1
                        case 4:
                            let decoded = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                characters[readOffset + 3],
                                using: table
                            )
                            bytes[writeOffset] = decoded.0
                            bytes[writeOffset + 1] = decoded.1
                            writeOffset += 2
                        case 5:
                            let decoded = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                characters[readOffset + 3],
                                characters[readOffset + 4],
                                using: table
                            )
                            bytes[writeOffset] = decoded.0
                            bytes[writeOffset + 1] = decoded.1
                            bytes[writeOffset + 2] = decoded.2
                            writeOffset += 3
                        case 7:
                            let decoded = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                characters[readOffset + 3],
                                characters[readOffset + 4],
                                characters[readOffset + 5],
                                characters[readOffset + 6],
                                using: table
                            )
                            bytes[writeOffset] = decoded.0
                            bytes[writeOffset + 1] = decoded.1
                            bytes[writeOffset + 2] = decoded.2
                            bytes[writeOffset + 3] = decoded.3
                            writeOffset += 4
                        case encodedBlockSize:
                            let decoded = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                characters[readOffset + 3],
                                characters[readOffset + 4],
                                characters[readOffset + 5],
                                characters[readOffset + 6],
                                characters[readOffset + 7],
                                using: table
                            )
                            bytes[writeOffset] = decoded.0
                            bytes[writeOffset + 1] = decoded.1
                            bytes[writeOffset + 2] = decoded.2
                            bytes[writeOffset + 3] = decoded.3
                            bytes[writeOffset + 4] = decoded.4
                            writeOffset += 5
                        default:
                            failure = .incompleteBlock
                            break blocks
                        }
                    } catch {
                        failure = error
                        break blocks
                    }
                    readOffset += blockSize
                }
                initializedCount = writeOffset
            }
            if let failure { return .failure(failure) }
            return .success(bytes)
        }
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
