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
}
