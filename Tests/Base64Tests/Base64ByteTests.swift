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

@testable import Base64

/// Covers the byte-native API added in 0.4.0. `Base64Tests` covers the same ground through
/// the deprecated `Data`/`String` surface.
@Suite("Base 64 Byte Tests")
struct Base64ByteTests {

    let plaintext = Array("yes mani !".utf8)

    /// The multibase test vectors for "yes mani !", with the prefix character stripped.
    @Test func testEncodesMultibaseVectors() {
        #expect(Base64.encodedString(plaintext, variant: .standard, pad: .unpadded) == "eWVzIG1hbmkgIQ")
        #expect(Base64.encodedString(plaintext, variant: .standard, pad: .padded) == "eWVzIG1hbmkgIQ==")
        #expect(Base64.encodedString(plaintext, variant: .url, pad: .unpadded) == "eWVzIG1hbmkgIQ")
        #expect(Base64.encodedString(plaintext, variant: .url, pad: .padded) == "eWVzIG1hbmkgIQ==")
    }

    @Test func testDecodesPaddedAndUnpadded() throws {
        for variant in [Base64.Variant.standard, .url] {
            #expect(try Base64.decode("eWVzIG1hbmkgIQ", variant: variant) == plaintext)
            #expect(try Base64.decode("eWVzIG1hbmkgIQ==", variant: variant) == plaintext)
        }
    }

    /// The URL alphabet is a distinct 64 entry table, not a post-hoc `-`/`_` substitution.
    @Test func testUrlAlphabet() throws {
        let allOnes = [UInt8](repeating: 0xFF, count: 3)
        #expect(Base64.encodedString(allOnes, variant: .standard, pad: .unpadded) == "////")
        #expect(Base64.encodedString(allOnes, variant: .url, pad: .unpadded) == "____")
        #expect(Base64.encodedString([0xFB], variant: .standard) == "+w==")
        #expect(Base64.encodedString([0xFB], variant: .url) == "-w==")
        #expect(try Base64.decode("____", variant: .url) == allOnes)
        #expect(try Base64.decode("////", variant: .standard) == allOnes)
    }

    /// `.url` still *decodes* the standard alphabet's `+` and `/`, which is what the
    /// pre-0.4.0 substitute-then-decode implementation did. `.standard` stays strict.
    @Test func testUrlDecodingAcceptsStandardCharacters() throws {
        #expect(try Base64.decode(Array("////".utf8), variant: .url) == [UInt8](repeating: 0xFF, count: 3))
        #expect(try Base64.decode(Array("+w==".utf8), variant: .url) == [0xFB])
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base64.decode(Array("____".utf8)) }
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base64.decode(Array("-w==".utf8)) }
    }

    /// A slice encodes without first being copied into an array.
    @Test func testEncodesASliceWithoutCopying() {
        let padded = Array("<<>>".utf8) + plaintext
        #expect(Base64.encodedString(padded.dropFirst(4), pad: .unpadded) == "eWVzIG1hbmkgIQ")
    }

    @Test func testEmptyInput() throws {
        #expect(Base64.encode([UInt8]()) == [UInt8]())
        #expect(try Base64.decode("") == [UInt8]())
        #expect(try Base64.decode("====") == [UInt8]())
    }

    @Test func testRoundTripsEveryBlockRemainderInEveryVariant() throws {
        let bytes = (0...255).map { UInt8($0) }
        for variant in [Base64.Variant.standard, .url] {
            for length in 0...16 {
                let payload = Array(bytes.prefix(length))
                for pad in [PadOption.padded, .unpadded] {
                    let encoded = Base64.encode(payload, variant: variant, pad: pad)
                    #expect(try Base64.decode(encoded, variant: variant) == payload)
                }
            }
        }
        // The whole byte range in one go, which lands on a 1-byte final block.
        #expect(try Base64.decode(Base64.encode(bytes)) == bytes)
    }

    @Test func testRejectsCharactersOutsideTheAlphabet() {
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base64.decode(Array("****".utf8)) }
        // A character after the padding is malformed too.
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base64.decode(Array("+w==A".utf8)) }
    }

    /// A single trailing character carries 6 bits, fewer than a byte.
    @Test func testRejectsIncompleteBlocks() {
        #expect(throws: BasesError.incompleteBlock) { try Base64.decode(Array("A".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base64.decode(Array("eWVzA".utf8)) }
    }

    @Test func testAlphabetsAreExposed() {
        #expect(
            Base64.Variant.standard.alphabet.characterString
                == "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        )
        #expect(
            Base64.Variant.url.alphabet.characterString
                == "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        )
    }
}
