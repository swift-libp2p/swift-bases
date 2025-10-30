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

@testable import Base8

@Suite("Base 8 Tests")
struct Base8Tests {

    let debug: Bool = false

    @Test func testEncode() {
        let tests = [
            "Decentralize everything!!": "2106254331267164344605543227514510062566312711713506415133463441102=====",
            "yes mani !": "362625631006654133464440102=====",
            "hello world": "320625543306744035667562330620==",
        ]

        for test in tests {
            let encoded = Base8.encode(test.key)
            if debug { print("Base8.encode(\(test.key)) => \(encoded)") }
            #expect(encoded == test.value)
        }
    }

    @Test func testDecode() throws {
        let tests = [
            "Decentralize everything!!": "2106254331267164344605543227514510062566312711713506415133463441102",
            "yes mani !": "362625631006654133464440102=====",
            "hello world": "320625543306744035667562330620",
        ]

        for test in tests {
            do {
                let d = try Base8.decode(test.value)
                let str = String(data: d, encoding: .ascii)
                if debug { print("Base8.decode(\(test.value)) => \(str ?? "nil")") }
                #expect(str == test.key)
            } catch {
                if debug { print("Error: \(error.localizedDescription)") }
                throw error
            }
        }
    }

    @Test func testLeadingZero() {
        let decoded = "\0yes mani !"
        let encoded = "000745453462015530267151100204=="
        #expect(Base8.encode(decoded) == encoded)
        #expect((try? Base8.decodeToString(encoded)) == decoded)
    }

    @Test func testTwoLeadingZeros() {
        let decoded = "\0\0yes mani !"
        let encoded = "00000171312714403326055632220041"
        #expect(Base8.encode(decoded) == encoded)
        #expect((try? Base8.decodeToString(encoded)) == decoded)
    }

    @Test func testEncodeWithOptions() {
        #expect(Base8.encode("yes mani !", options: .pad(true)) == "362625631006654133464440102=====")
        #expect(Base8.encode("yes mani !", options: .pad(false)) == "362625631006654133464440102")
    }
}
