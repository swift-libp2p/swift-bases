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

import XCTest

@testable import Base2

final class Base2Tests: XCTestCase {
    func testBase2() {
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
            XCTAssertEqual(byte.binaryEncoded(), str)
        }

        let bytes: [UInt8] = [0]
        XCTAssertEqual(bytes.binaryEncoded(), "00000000")

        let bytes2: [UInt8] = [1]
        XCTAssertEqual(bytes2.binaryEncoded(), "00000001")
    }

    func testBase2EncodingStringExtensions() {
        let testString = "Hello World"
        let encoded = testString.binaryEncoded(using: .utf8, byteSpacing: true)
        //print(encoded ?? "NIL")

        let decoded = encoded!.binaryDecodedString
        //print(decoded ?? "NIL")

        XCTAssertEqual(testString, decoded)
    }

    func testBase2EncodingDataExtensions() {
        let testData = "Hello World".data(using: .utf8)
        let encoded = testData?.binaryEncoded()
        //print(encoded ?? "NIL")

        let decoded = encoded!.binaryDecoded
        //print(decoded)

        XCTAssertEqual(testData, decoded)
    }
}
