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
        withByteBuffer(bytes) { encodeCore($0, pad: pad) }
    }

    private static func encodeCore(_ bytes: UnsafeBufferPointer<Byte>, pad: PadOption) -> [UInt8] {
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

        return alphabet.withEncodingTable { table in
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
        switch withByteBuffer(characters, { decodeCore($0) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    /// Decodes a base8 `String` into bytes.
    public static func decode(_ string: some StringProtocol) throws(BasesError) -> [UInt8] {
        switch withByteBuffer(string, { decodeCore($0) }) {
        case .success(let bytes): return bytes
        case .failure(let error): throw error
        }
    }

    private static func decodeCore(
        _ characters: UnsafeBufferPointer<EncodedChar>
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

        return alphabet.withDecodingTable { table in
            var failure: BasesError? = nil
            let bytes = [UInt8](unsafeUninitializedCapacity: capacity) { bytes, initializedCount in
                var readOffset = 0
                var writeOffset = 0
                blocks: while readOffset < encodedCount {
                    let blockSize = min(encodedBlockSize, encodedCount - readOffset)
                    do throws(BasesError) {
                        switch blockSize {
                        case 3:
                            bytes[writeOffset] = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                using: table
                            )
                            writeOffset += 1
                        case 6:
                            let decoded = try decodeBlock(
                                characters[readOffset],
                                characters[readOffset + 1],
                                characters[readOffset + 2],
                                characters[readOffset + 3],
                                characters[readOffset + 4],
                                characters[readOffset + 5],
                                using: table
                            )
                            bytes[writeOffset] = decoded.0
                            bytes[writeOffset + 1] = decoded.1
                            writeOffset += 2
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
                            writeOffset += 3
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
        case 1: 3
        case 2: 6
        default: encodedBlockSize
        }
    }
}
