//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2025 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation

public enum Base8 {
    public enum NullCharOpts: Sendable {
        case drop
        case encode
        case literal
    }

    public enum Base8Options: Sendable {
        case pad(Bool)
        case nullChar(NullCharOpts)
    }

    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 3
    /// The size of a block after encoding, measured in bytes.
    private static let encodedBlockSize = 8

    public static func encode(_ str: String, options: Base8Options...) -> String {
        // Encode via UTF-8 so non-ASCII input is handled instead of trapping.
        // A Swift String's UTF-8 view is always available, so this never fails.
        // ASCII input produces identical bytes to the previous `.ascii` encoding.
        self.encode(Data(str.utf8), options: options)
    }

    /// Variadic Overload
    public static func encode(_ d: Data, options: Base8Options...) -> String { self.encode(d, options: options) }

    public static func encode(_ d: Data, options: [Base8Options]) -> String {
        var data = d
        for opt in options {
            if case .nullChar(let o) = opt { data = leadingNullChars(data: data, opt: o) }
        }

        let unencodedByteCount = data.count

        let encodedByteCount = byteCount(encoding: unencodedByteCount)
        let encodedBytes = UnsafeMutablePointer<EncodedChar>.allocate(capacity: encodedByteCount)

        let alphabet = Base8Alphabet()

        data.withUnsafeBytes { unencodedBytes in
            var encodedWriteOffset = 0
            for unencodedReadOffset in stride(from: 0, to: unencodedByteCount, by: unencodedBlockSize) {
                let nextBlockSize = min(unencodedBlockSize, unencodedByteCount - unencodedReadOffset)
                let nextBlockSlice = unencodedBytes[unencodedReadOffset..<unencodedReadOffset + nextBlockSize]
                let nextBlockBytes = UnsafeRawBufferPointer(rebasing: nextBlockSlice)

                let nextChars = encodeBlock(bytes: nextBlockBytes, using: alphabet)
                encodedBytes[encodedWriteOffset + 0] = nextChars.0
                encodedBytes[encodedWriteOffset + 1] = nextChars.1
                encodedBytes[encodedWriteOffset + 2] = nextChars.2
                encodedBytes[encodedWriteOffset + 3] = nextChars.3
                encodedBytes[encodedWriteOffset + 4] = nextChars.4
                encodedBytes[encodedWriteOffset + 5] = nextChars.5
                encodedBytes[encodedWriteOffset + 6] = nextChars.6
                encodedBytes[encodedWriteOffset + 7] = nextChars.7

                encodedWriteOffset += encodedBlockSize
            }
        }

        // The Data instance takes ownership of the allocated bytes and will handle deallocation.
        let encodedData = Data(
            bytesNoCopy: encodedBytes,
            count: encodedByteCount,
            deallocator: .free
        )
        guard var encodedString = String(data: encodedData, encoding: .ascii) else {
            fatalError("Internal Error: Encoded data could not be encoded as ASCII (\(encodedData))")
        }

        for option in options {
            if case .pad(false) = option {
                encodedString = String(encodedString.reversed().drop(while: { $0 == "=" }).reversed())
            }
        }

        return encodedString
    }

    private static func leadingNullChars(data: Data, opt: NullCharOpts) -> Data {
        switch opt {
        case .drop:
            // Drop actual leading null bytes (0x00). The multibase spec has no notion of
            // an escaped "\x00" text sequence, so we operate on real bytes — matching the
            // semantics Base32 already uses (`d.drop(while: { $0 == 0 })`).
            return data.drop(while: { $0 == 0 })
        case .encode, .literal:
            // Preserve leading null bytes; they are encoded like any other byte.
            return data
        }
    }

    private static func byteCount(encoding unencodedByteCount: Int) -> Int {
        let fullBlockCount = unencodedByteCount / unencodedBlockSize
        let remainingRawBytes = unencodedByteCount % unencodedBlockSize
        let blockCount = remainingRawBytes > 0 ? fullBlockCount + 1 : fullBlockCount
        return blockCount * encodedBlockSize
    }

    public static func decodeToString(_ string: String, using strEncoding: String.Encoding = .ascii) throws -> String {
        guard let str = String(data: try self.decode(string), encoding: strEncoding) else {
            throw Base8.Error.nonAsciiCompliant
        }
        return str
    }

    public static func decode(_ string: String) throws -> Data {
        guard let encodedData = string.data(using: String.Encoding.ascii) else {
            throw Error.nonAlphabetCharacter
        }
        let encodedByteCount = nonPaddingByteCount(encodedData: encodedData)

        let decodedByteCount = try byteCount(decoding: encodedByteCount)
        // Empty (or all-padding) input decodes to no bytes. Return early so we don't
        // force-unwrap the base address of a zero-byte allocation.
        guard decodedByteCount > 0 else { return Data() }
        let decodedBytes = UnsafeMutableRawBufferPointer.allocate(
            byteCount: decodedByteCount,
            alignment: MemoryLayout<Byte>.alignment
        )
        let alphabet = Base8Alphabet()

        try encodedData.withUnsafeBytes { rawBuffer in
            let encodedChars: UnsafePointer<EncodedChar> = rawBuffer.bindMemory(to: EncodedChar.self).baseAddress!

            var decodedWriteOffset = 0
            for encodedReadOffset in stride(from: 0, to: encodedByteCount, by: encodedBlockSize) {
                let chars = encodedChars + encodedReadOffset

                switch min(encodedByteCount - encodedReadOffset, encodedBlockSize) {
                case 3:
                    let byte = try decodeBlock(chars[0], chars[1], chars[2], using: alphabet)
                    decodedBytes[decodedWriteOffset + 0] = byte
                case 6:
                    let bytes = try decodeBlock(
                        chars[0],
                        chars[1],
                        chars[2],
                        chars[3],
                        chars[4],
                        chars[5],
                        using: alphabet
                    )
                    decodedBytes[decodedWriteOffset + 0] = bytes.0
                    decodedBytes[decodedWriteOffset + 1] = bytes.1
                case 8:
                    let bytes =
                        try decodeBlock(
                            chars[0],
                            chars[1],
                            chars[2],
                            chars[3],
                            chars[4],
                            chars[5],
                            chars[6],
                            chars[7],
                            using: alphabet
                        )
                    decodedBytes[decodedWriteOffset + 0] = bytes.0
                    decodedBytes[decodedWriteOffset + 1] = bytes.1
                    decodedBytes[decodedWriteOffset + 2] = bytes.2
                default:
                    throw Base8.Error.incompleteBlock
                }

                decodedWriteOffset += unencodedBlockSize
            }
        }

        // The Data instance takes ownership of the allocated bytes and will handle deallocation.
        return Data(bytesNoCopy: decodedBytes.baseAddress!, count: decodedByteCount, deallocator: .free)
    }

    private static func nonPaddingByteCount(encodedData: Data) -> Int {
        let paddingCharacter = Base8Alphabet.paddingCharacter
        if let lastNonPaddingCharacterIndex = encodedData.lastIndex(where: { $0 != paddingCharacter }) {
            return lastNonPaddingCharacterIndex + 1
        }
        return 0
    }

    private static func byteCount(decoding encodedByteCount: Int) throws -> Int {
        let extraEncodedBytes = encodedByteCount % encodedBlockSize
        let extraDecodedBytes: Int
        switch extraEncodedBytes {
        case 0:
            extraDecodedBytes = 0
        case 3:
            extraDecodedBytes = 1
        case 6:
            extraDecodedBytes = 2
        default:
            throw Error.incompleteBlock
        }
        return (encodedByteCount / encodedBlockSize) * unencodedBlockSize + extraDecodedBytes
    }

    public enum Error: Swift.Error, Sendable {
        /// The input string ends with an incomplete encoded block
        case incompleteBlock
        /// The input string contains a character not in the encoding alphabet
        case nonAlphabetCharacter

        case nonNumericCharacter
        /// The last encoded character has non-zero padding bits
        /// https://tools.ietf.org/html/rfc4648#section-3.5
        case strayBits
        /// If we can't decode data into an Ascii string
        case nonAsciiCompliant
    }
}

extension Data {
    /// Base8-encodes these bytes. Convenience wrapper around `Base8.encode(_:options:)`.
    public func base8Encoded(options: Base8.Base8Options...) -> String {
        Base8.encode(self, options: options)
    }

    /// Decodes a Base8 string into bytes. Convenience wrapper around `Base8.decode(_:)`.
    public init(base8Encoded string: String) throws {
        self = try Base8.decode(string)
    }
}
