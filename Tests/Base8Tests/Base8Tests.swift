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

    /// `.nullChar(.drop)` should strip actual leading null bytes (0x00), not the literal
    /// text "\x00". After dropping, the result matches encoding the payload alone.
    @Test func testNullCharDropRemovesLeadingNullBytes() {
        let withNulls = "\0\0yes mani !"
        #expect(Base8.encode(withNulls, options: .nullChar(.drop)) == Base8.encode("yes mani !"))
        // Without the option, leading null bytes are preserved (encoded), so they differ.
        #expect(Base8.encode(withNulls) != Base8.encode("yes mani !"))
    }

    @Test func testEncodeWithOptions() {
        #expect(Base8.encode("yes mani !", options: .pad(true)) == "362625631006654133464440102=====")
        #expect(Base8.encode("yes mani !", options: .pad(false)) == "362625631006654133464440102")
    }

    /// Non-ASCII input previously trapped because `encode(String)` force-unwrapped
    /// `data(using: .ascii)`. It now encodes via UTF-8 and round-trips.
    @Test func testEncodeNonASCIIDoesNotCrash() throws {
        let input = "café 🚀"
        let encoded = Base8.encode(input)
        let decoded = try Base8.decode(encoded)
        #expect(decoded == Data(input.utf8))
    }

    /// Empty input previously risked force-unwrapping the base address of a zero-byte
    /// allocation. It should decode to empty `Data`.
    @Test func testDecodeEmptyReturnsEmptyData() throws {
        #expect(try Base8.decode("") == Data())
    }

    /// The Base8 alphabet is '0'-'7'. Character '8' (ASCII 56) must be rejected;
    /// previously the decoder's guard `48...56` accepted it and silently produced wrong bytes.
    @Test func testDecodeRejectsCharacterEight() {
        #expect(throws: Base8.Error.nonNumericCharacter) {
            try Base8.decode("888=====")
        }
        #expect(throws: Base8.Error.nonNumericCharacter) {
            try Base8.decode("008=====")
        }
        // Boundary: '7' is the highest valid octal digit and must still be accepted.
        #expect(throws: Never.self) {
            try Base8.decode("700=====")
        }
    }

    /// The Data convenience wrappers mirror the enum's encode/decode.
    @Test func testDataConvenienceRoundTrip() throws {
        let data = Data("hello world".utf8)
        let encoded = data.base8Encoded()
        #expect(encoded == Base8.encode("hello world"))
        #expect(try Data(base8Encoded: encoded) == data)
    }

    /// Compiles only if the public option/error types are Sendable.
    @Test func testSendableConformances() {
        let _: any Sendable = Base8.Base8Options.pad(true)
        let _: any Sendable = Base8.NullCharOpts.drop
        let _: any Sendable = Base8.Error.incompleteBlock
    }
}
