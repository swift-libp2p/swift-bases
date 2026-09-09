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

@testable import Base8

/// Covers the byte-native API added in 0.4.0. `Base8Tests` covers the same ground through
/// the deprecated `Data`/`String` surface.
@Suite("Base 8 Byte Tests")
struct Base8ByteTests {

    let plaintext = Array("yes mani !".utf8)

    /// The multibase test vector, with the `7` prefix character stripped.
    let encoded = "362625631006654133464440102"

    @Test func testEncodesMultibaseVector() {
        #expect(Base8.encodedString(plaintext, pad: .unpadded) == encoded)
        #expect(Base8.encodedString(plaintext) == encoded + "=====")
        #expect(Base8.encode(plaintext, pad: .unpadded) == Array(encoded.utf8))
    }

    @Test func testDecodesPaddedAndUnpadded() throws {
        #expect(try Base8.decode(encoded) == plaintext)
        #expect(try Base8.decode(encoded + "=====") == plaintext)
        #expect(try Base8.decode(Array(encoded.utf8)) == plaintext)
    }

    /// A slice encodes without first being copied into an array.
    @Test func testEncodesASliceWithoutCopying() {
        let padded = Array("<<>>".utf8) + plaintext
        #expect(Base8.encodedString(padded.dropFirst(4), pad: .unpadded) == encoded)
    }

    /// Leading null bytes are dropped by slicing the input, which is what the pre-0.4.0
    /// `.nullChar(.drop)` option did internally.
    @Test func testDroppingLeadingNullBytes() {
        let withNulls: [UInt8] = [0, 0] + plaintext
        #expect(
            Base8.encodedString(withNulls.drop(while: { $0 == 0 }))
                == Base8.encodedString(plaintext)
        )
        #expect(Base8.encodedString(withNulls) != Base8.encodedString(plaintext))
    }

    @Test func testEmptyInput() throws {
        #expect(Base8.encode([UInt8]()) == [UInt8]())
        #expect(try Base8.decode("") == [UInt8]())
    }

    @Test func testRoundTripsEveryBlockRemainder() throws {
        let bytes = (0...255).map { UInt8($0) }
        for length in 0...16 {
            let payload = Array(bytes.prefix(length))
            for pad in [PadOption.padded, .unpadded] {
                #expect(try Base8.decode(Base8.encode(payload, pad: pad)) == payload)
            }
        }
    }

    @Test func testRejectsCharactersOutsideTheAlphabet() {
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base8.decode(Array("888".utf8)) }
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base8.decode(Array("00a".utf8)) }
        // A character after the padding is malformed too.
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base8.decode(Array("000=====0".utf8)) }
    }

    @Test func testRejectsIncompleteBlocks() {
        // 3 and 6 characters are the only valid partial blocks.
        #expect(throws: BasesError.incompleteBlock) { try Base8.decode(Array("0".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base8.decode(Array("00".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base8.decode(Array("0000".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base8.decode(Array("0000000".utf8)) }
    }

    /// A 3-character block carries 9 bits but only 8 of them are a byte, the spare bit
    /// must be zero.
    @Test func testRejectsStrayBits() throws {
        #expect(try Base8.decode("000") == [0x00])
        #expect(throws: BasesError.strayBits) { try Base8.decode(Array("001".utf8)) }
    }

    @Test func testAlphabetIsExposed() {
        #expect(Base8.alphabet.characterString == "01234567")
    }
}
