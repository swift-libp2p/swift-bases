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

@testable import Base2

@Suite("Base 2 Byte Tests")
struct Base2ByteTests {

    let plaintext = Array("yes mani !".utf8)
    
    /// The multibase test vector, with the `0` prefix character stripped.
    let encoded = "01111001011001010111001100100000011011010110000101101110011010010010000000100001"

    @Test func testEncodesMultibaseVector() {
        #expect(Base2.encodedString(plaintext) == encoded)
        #expect(Base2.encode(plaintext) == Array(encoded.utf8))
    }

    @Test func testDecodesMultibaseVector() throws {
        #expect(try Base2.decode(encoded) == plaintext)
        #expect(try Base2.decode(Array(encoded.utf8)) == plaintext)
    }

    /// A slice encodes without first being copied into an array.
    @Test func testEncodesASliceWithoutCopying() {
        let padded = Array("<<>>".utf8) + plaintext
        #expect(Base2.encodedString(padded.dropFirst(4)) == encoded)
    }

    @Test func testByteSpacing() throws {
        let spaced = Base2.encodedString([0x48, 0x65], byteSpacing: true)
        #expect(spaced == "01001000 01100101")
        // Spaces are ignored on the way back, so both forms round-trip.
        #expect(try Base2.decode(spaced) == [0x48, 0x65])
        #expect(try Base2.decode("0100100001100101") == [0x48, 0x65])
    }

    @Test func testEmptyInput() throws {
        #expect(Base2.encode([UInt8]()) == [UInt8]())
        #expect(Base2.encodedString([UInt8]()) == "")
        #expect(try Base2.decode("") == [UInt8]())
    }

    @Test func testRoundTripsEveryByte() throws {
        let bytes = (0...255).map { UInt8($0) }
        for byteSpacing in [true, false] {
            #expect(try Base2.decode(Base2.encode(bytes, byteSpacing: byteSpacing)) == bytes)
        }
    }

    @Test func testRejectsNonBinaryCharacters() {
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base2.decode("0000000X") }
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base2.decode("00000002") }
    }

    /// A bit count that isn't a multiple of eight doesn't describe whole bytes. The
    /// pre-0.4.0 `String.binaryDecoded` returned empty `Data` here instead.
    @Test func testRejectsPartialBytes() {
        #expect(throws: BasesError.invalidLength) { try Base2.decode("101") }
        #expect(throws: BasesError.invalidLength) { try Base2.decode("000000001") }
    }
}
