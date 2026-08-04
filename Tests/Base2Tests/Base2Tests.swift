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
import Testing

@testable import Base2

@Suite("Base 2 Tests")
struct Base2Tests {
    @Test func testBase2() {
        let tests: [String: [UInt8]] = [
            "00000000": [0],
            "00000001": [1],
            "00000010": [2],
            "00000011": [3],
            "00000100": [4],
            "00000101": [5],
            "00000110": [6],
            "00000111": [7],
            "00001000": [8],
            "00001001": [9],
            "00001010": [10],
            "00001011": [11],
            "00001100": [12],
            "00001101": [13],
            "00001110": [14],
            "00001111": [15],
            "00010000": [16],
            "00010001": [17],
            "00010010": [18],
            "00010011": [19],
            "00010100": [20],
            "11111111": [255],
        ]

        for (str, byte) in tests {
            #expect(byte.binaryEncoded() == str)
        }

        let bytes: [UInt8] = [0]
        #expect(bytes.binaryEncoded() == "00000000")

        let bytes2: [UInt8] = [1]
        #expect(bytes2.binaryEncoded() == "00000001")
    }

    @Test func testBase2EncodingStringExtensions() throws {
        let testString = "Hello World"

        let encoded = try #require(testString.binaryEncoded(using: .utf8, byteSpacing: true))
        #expect(
            encoded
                == "01001000 01100101 01101100 01101100 01101111 00100000 01010111 01101111 01110010 01101100 01100100"
        )

        let decoded = encoded.binaryDecodedString
        #expect(testString == decoded)
    }

    @Test func testBase2EncodingDataExtensions() throws {
        let testData = try #require("Hello World".data(using: .utf8))

        let encoded = testData.binaryEncoded()
        #expect(encoded == "0100100001100101011011000110110001101111001000000101011101101111011100100110110001100100")

        let decoded = encoded.binaryDecoded
        #expect(testData == decoded)
    }

    @Test func testDecodeRejectsInvalidCharacters() {
        #expect(throws: Base2Error.invalidBinaryCharacter) {
            try Data(binaryString: "0000000X")
        }
    }

    /// A binary string whose length isn't a multiple of 8 doesn't represent whole bytes.
    @Test func testDecodeRejectsNonByteAlignedLength() {
        #expect(throws: Base2Error.invalidBinaryLength) {
            try Data(binaryString: "101")
        }
        // The lenient computed property returns empty Data for the same input.
        #expect("101".binaryDecoded == Data())
    }

    /// `binaryDecodedString` now decodes as UTF-8, so multi-byte scalars round-trip.
    @Test func testBinaryDecodedStringHandlesUTF8() throws {
        let input = "café 🚀"
        let encoded = try #require(input.binaryEncoded(using: .utf8))
        #expect(encoded.binaryDecodedString == input)
    }

    /// Compiles only if the public error type is Sendable.
    @Test func testSendableConformances() {
        let _: any Sendable = Base2Error.invalidBinaryCharacter
        let _: any Sendable = Base2Error.invalidBinaryLength
    }
}
