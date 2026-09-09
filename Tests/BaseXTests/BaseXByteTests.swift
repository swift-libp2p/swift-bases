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

@testable import BaseX

/// Covers the byte-native API added in 0.4.0. `BaseXTests` covers the same ground through
/// the deprecated `Data`/`String` surface.
@Suite("Base X Byte Tests")
struct BaseXByteTests {

    let plaintext = Array("yes mani !".utf8)

    /// The multibase test vectors for "yes mani !", with the prefix character stripped.
    static let vectors: [(base: BaseX.Alphabets, encoded: String)] = [
        (.base10Decimal, "573277761329450583662625"),
        (.base16Hex, "796573206d616e692021"),
        (.base16HexUpper, "796573206D616E692021"),
        (.base36, "2lcpzo5yikidynfl"),
        (.base36Upper, "2LCPZO5YIKIDYNFL"),
        (.base58BTC, "7paNL19xttacUY"),
        (.base58Flickr, "7Pznk19XTTzBtx"),
    ]

    @Test func testEncodesMultibaseVectors() {
        for vector in Self.vectors {
            #expect(BaseX.encodedString(plaintext, into: vector.base) == vector.encoded)
            #expect(BaseX.encode(plaintext, into: vector.base) == Array(vector.encoded.utf8))
        }
    }

    @Test func testDecodesMultibaseVectors() throws {
        for vector in Self.vectors {
            #expect(try BaseX.decode(vector.encoded, as: vector.base) == plaintext)
            #expect(try BaseX.decode(Array(vector.encoded.utf8), as: vector.base) == plaintext)
        }
    }

    /// Leading zero bytes carry no value positionally, so each is rendered as one leading
    /// zero digit, two for base16, where every byte is exactly two digits, and restored
    /// on the way back.
    @Test func testLeadingZeroBytesRoundTrip() throws {
        for vector in Self.vectors {
            let leader = vector.base.alphabet.leader
            for zeros in 1...3 {
                let payload = [UInt8](repeating: 0, count: zeros) + plaintext
                let encoded = BaseX.encode(payload, into: vector.base)
                let expectedLeaders = vector.base.isHex ? zeros * 2 : zeros
                #expect(encoded.prefix(expectedLeaders).allSatisfy { $0 == leader })
                #expect(try BaseX.decode(encoded, as: vector.base) == payload)
            }
        }
    }

    /// An all-zero payload is all leading zeros and nothing else.
    @Test func testAllZeroBytes() throws {
        let zeros = [UInt8](repeating: 0, count: 32)
        #expect(BaseX.encodedString(zeros, into: .base16Hex) == String(repeating: "0", count: 64))
        #expect(BaseX.encodedString(zeros, into: .base58BTC) == String(repeating: "1", count: 32))
        #expect(try BaseX.decode(Array(repeating: UInt8(ascii: "1"), count: 32), as: .base58BTC) == zeros)
    }

    /// Base16 and base36 decode either case, which is what lets the multibase layer stop
    /// lowercasing (or uppercasing) the input first.
    @Test func testDecodingIsCaseInsensitiveWhereTheAlphabetIsSingleCase() throws {
        #expect(try BaseX.decode("796573206D616E692021", as: .base16Hex) == plaintext)
        #expect(try BaseX.decode("796573206d616e692021", as: .base16HexUpper) == plaintext)
        #expect(try BaseX.decode("2LCPZO5YIKIDYNFL", as: .base36) == plaintext)
        #expect(try BaseX.decode("2lcpzo5yikidynfl", as: .base36Upper) == plaintext)
    }

    /// Base58's alphabet uses both cases as distinct digits, so it must stay case-sensitive.
    @Test func testBase58IsCaseSensitive() throws {
        #expect(try BaseX.decode("7paNL19xttacUY", as: .base58BTC) == plaintext)
        #expect(try BaseX.decode(Array("7PANL19XTTACUY".utf8), as: .base58BTC) != plaintext)
    }

    /// A slice encodes without first being copied into an array.
    @Test func testEncodesASliceWithoutCopying() {
        let padded = Array("<<>>".utf8) + plaintext
        #expect(BaseX.encodedString(padded.dropFirst(4), into: .base58BTC) == "7paNL19xttacUY")
    }

    @Test func testEmptyInput() throws {
        for vector in Self.vectors {
            #expect(BaseX.encode([UInt8](), into: vector.base) == [UInt8]())
            #expect(try BaseX.decode([UInt8](), as: vector.base) == [UInt8]())
        }
    }

    @Test func testRoundTripsALongPayload() throws {
        let bytes = (0...255).map { UInt8($0) }
        for vector in Self.vectors {
            #expect(try BaseX.decode(BaseX.encode(bytes, into: vector.base), as: vector.base) == bytes)
        }
    }

    @Test func testRejectsCharactersOutsideTheAlphabet() {
        #expect(throws: BasesError.nonAlphabetCharacter) { try BaseX.decode(Array("zz".utf8), as: .base16Hex) }
        #expect(throws: BasesError.nonAlphabetCharacter) { try BaseX.decode(Array("0OIl".utf8), as: .base58BTC) }
    }

    /// Every byte is exactly two base16 digits, so an odd number of them is a length
    /// problem rather than a bad character.
    @Test func testRejectsOddNumberOfHexDigits() {
        #expect(throws: BasesError.invalidLength) { try BaseX.decode(Array("abc".utf8), as: .base16Hex) }
        #expect(throws: BasesError.invalidLength) { try BaseX.decode(Array("ABC".utf8), as: .base16HexUpper) }
        // "0x" is tolerated as a prefix, so it doesn't affect the digit count.
        #expect(throws: BasesError.invalidLength) { try BaseX.decode(Array("0xabc".utf8), as: .base16Hex) }
        #expect(throws: Never.self) { try BaseX.decode(Array("0xabcd".utf8), as: .base16Hex) }
    }

    /// A custom alphabet round-trips through the general positional path.
    @Test func testCustomAlphabet() throws {
        let base4 = BaseX.Alphabets.custom("0123")
        let encoded = BaseX.encode(plaintext, into: base4)
        #expect(try BaseX.decode(encoded, as: base4) == plaintext)
        #expect(base4.alphabet.radix == 4)
    }

    /// The alphabets the multibase layer reads instead of duplicating the strings.
    @Test func testAlphabetsAreExposed() {
        #expect(BaseX.Alphabets.base10Decimal.alphabet.characterString == "0123456789")
        #expect(BaseX.Alphabets.base16Hex.alphabet.characterString == "0123456789abcdef")
        #expect(BaseX.Alphabets.base16HexUpper.alphabet.characterString == "0123456789ABCDEF")
        #expect(BaseX.Alphabets.base36.alphabet.characterString == "0123456789abcdefghijklmnopqrstuvwxyz")
        #expect(BaseX.Alphabets.base36Upper.alphabet.characterString == "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        #expect(
            BaseX.Alphabets.base58BTC.alphabet.characterString
                == "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        )
        #expect(
            BaseX.Alphabets.base58Flickr.alphabet.characterString
                == "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
        )
    }
}
