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

import Testing

@testable import BasesCore

@Suite("Alphabet Tests")
struct AlphabetTests {

    @Test func testValuesAndCharacters() throws {
        let alphabet = Alphabet("01234567")
        #expect(alphabet.radix == 8)
        #expect(alphabet.leader == UInt8(ascii: "0"))
        #expect(alphabet.characterString == "01234567")
        for value in 0..<8 {
            let character = alphabet.character(encoding: UInt8(value))
            #expect(character == UInt8(ascii: "0") + UInt8(value))
            #expect(try alphabet.value(decoding: character) == UInt8(value))
        }
    }

    @Test func testRejectsCharactersOutsideTheAlphabet() {
        let alphabet = Alphabet("01234567")
        #expect(!alphabet.contains(UInt8(ascii: "8")))
        #expect(throws: BasesError.nonAlphabetCharacter) {
            try alphabet.value(decoding: UInt8(ascii: "8"))
        }
        // Every byte outside the alphabet maps to the sentinel, including non-ASCII.
        #expect(alphabet.decodingTable[0xFF] == Alphabet.sentinel)
    }

    /// A case-insensitive alphabet decodes both cases to the same value, which is what
    /// removes the `.lowercased()` / `.uppercased()` copies the multibase layer used to make.
    @Test func testCaseInsensitiveDecoding() throws {
        let alphabet = Alphabet("0123456789ABCDEF", caseInsensitive: true)
        #expect(try alphabet.value(decoding: UInt8(ascii: "F")) == 15)
        #expect(try alphabet.value(decoding: UInt8(ascii: "f")) == 15)
        // Encoding still only ever emits the alphabet's own characters.
        #expect(alphabet.character(encoding: 15) == UInt8(ascii: "F"))
    }

    @Test func testCaseSensitiveAlphabetKeepsBothCasesDistinct() throws {
        let alphabet = Alphabet("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        #expect(alphabet.radix == 58)
        #expect(try alphabet.value(decoding: UInt8(ascii: "A")) != alphabet.value(decoding: UInt8(ascii: "a")))
        #expect(!alphabet.contains(UInt8(ascii: "0")))
        #expect(!alphabet.contains(UInt8(ascii: "l")))
    }

    @Test func testCaseTransforms() throws {
        let lower = Alphabet("ybndrfg8ejkmcpqxot1uwisza345h769", caseInsensitive: true)
        let upper = lower.uppercased()
        #expect(upper.characterString == "YBNDRFG8EJKMCPQXOT1UWISZA345H769")
        #expect(upper.lowercased().characterString == lower.characterString)
        // Both directions stay case-insensitive when decoding.
        #expect(try upper.value(decoding: UInt8(ascii: "y")) == 0)
        #expect(try lower.value(decoding: UInt8(ascii: "Y")) == 0)
    }

    @Test func testAliasesAcceptExtraCharacters() throws {
        let url = Alphabet(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
            aliases: [UInt8(ascii: "+"): 62, UInt8(ascii: "/"): 63]
        )
        #expect(try url.value(decoding: UInt8(ascii: "-")) == 62)
        #expect(try url.value(decoding: UInt8(ascii: "+")) == 62)
        #expect(try url.value(decoding: UInt8(ascii: "/")) == 63)
        // An alias is decode-only, encoding uses the alphabet's own character.
        #expect(url.character(encoding: 62) == UInt8(ascii: "-"))
    }

    @Test func testSizingBounds() {
        let base58 = Alphabet("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        #expect(base58.bitsPerDigitFloor == 5)
        #expect(base58.bitsPerDigitCeil == 6)
        // 10 bytes of base58 is 14 characters, the bound must not undershoot it.
        #expect(base58.maximumDigitCount(forByteCount: 10) >= 14)
        #expect(base58.maximumByteCount(forDigitCount: 14) >= 10)
        #expect(base58.maximumDigitCount(forByteCount: 0) == 0)
        #expect(base58.maximumByteCount(forDigitCount: 0) == 0)

        let base16 = Alphabet("0123456789abcdef")
        #expect(base16.bitsPerDigitFloor == 4)
        #expect(base16.bitsPerDigitCeil == 4)
    }

    @Test func testSendableAndHashableConformances() {
        let _: any Sendable = BasesError.strayBits
        let _: any Sendable = LetterCase.lower
        let _: any Sendable = PadOption.unpadded
        let _: any Sendable = NullCharOption.drop
        let _: any Sendable = Alphabet("01")
        #expect(Alphabet("01") == Alphabet("01"))
        #expect(Set([BasesError.strayBits, .strayBits]).count == 1)
    }

    @Test func testPadOptionBridgesBool() {
        #expect(PadOption(true) == .padded)
        #expect(PadOption(false) == .unpadded)
        #expect(PadOption.padded.isPadded)
    }
}
