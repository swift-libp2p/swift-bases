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

@testable import BaseX

@Suite("Base X Tests")
struct BaseXTests {
    let testString = "yes mani !"

    @Test func testBase10() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base10Decimal)
        #expect(try BaseX.decode(baseEncoded, as: .base10Decimal) == testString)

        #expect(try BaseX.decode("573277761329450583662625", as: .base10Decimal) == testString)
    }

    @Test func testBase16Lower() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base16Hex)
        #expect(try BaseX.decode(baseEncoded, as: .base16Hex) == testString)

        #expect(try BaseX.decode("796573206d616e692021", as: .base16Hex) == testString)
    }

    @Test func testBase16Upper() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base16HexUpper)
        #expect(try BaseX.decode(baseEncoded, as: .base16HexUpper) == testString)

        #expect(try BaseX.decode("796573206D616E692021", as: .base16HexUpper) == testString)
    }

    @Test func testBase36Lower() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base36)
        #expect(try BaseX.decode(baseEncoded, as: .base36) == testString)

        #expect(try BaseX.decode("2lcpzo5yikidynfl", as: .base36) == testString)
    }

    @Test func testBase36Upper() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base36Upper)
        #expect(try BaseX.decode(baseEncoded, as: .base36Upper) == testString)

        #expect(try BaseX.decode("2LCPZO5YIKIDYNFL", as: .base36Upper) == testString)
    }

    @Test func testBase58BTC() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base58BTC)
        #expect(try BaseX.decode(baseEncoded, as: .base58BTC) == testString)

        #expect(try BaseX.decode("7paNL19xttacUY", as: .base58BTC) == testString)
    }

    @Test func testBase58Flickr() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base58Flickr)
        #expect(try BaseX.decode(baseEncoded, as: .base58Flickr) == testString)

        #expect(try BaseX.decode("7Pznk19XTTzBtx", as: .base58Flickr) == testString)
    }

    // - MARK: Leading Zero
    let testStringLeadingZero = "\0yes mani !"

    @Test func testBase10LeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base10Decimal)
        #expect(try BaseX.decode(baseEncoded, as: .base10Decimal) == testStringLeadingZero)

        #expect(try BaseX.decode("0573277761329450583662625", as: .base10Decimal) == testStringLeadingZero)
    }

    @Test func testBase16LowerLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base16Hex)
        #expect(try BaseX.decode(baseEncoded, as: .base16Hex) == testStringLeadingZero)

        #expect(try BaseX.decode("00796573206d616e692021", as: .base16Hex) == testStringLeadingZero)
    }

    @Test func testBase16AllZeros() throws {
        /// Defaults to 32 bytes
        let zeros = [UInt8](repeating: 0, count: 32)
        let baseEncoded = BaseX.encode(Data(zeros), into: .base16Hex)
        let target = "0000000000000000000000000000000000000000000000000000000000000000"

        #expect(zeros.count == 32)
        #expect(
            zeros
                == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        )
        #expect(target.count == 64)
        #expect(baseEncoded.count == 64)
        #expect(baseEncoded == target)
    }

    @Test func testBase16UpperLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base16HexUpper)
        #expect(try BaseX.decode(baseEncoded, as: .base16HexUpper) == testStringLeadingZero)

        #expect(try BaseX.decode("00796573206D616E692021", as: .base16HexUpper) == testStringLeadingZero)
    }

    @Test func testBase36LowerLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base36)
        #expect(try BaseX.decode(baseEncoded, as: .base36) == testStringLeadingZero)

        #expect(try BaseX.decode("02lcpzo5yikidynfl", as: .base36) == testStringLeadingZero)
    }

    @Test func testBase36UpperLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base36Upper)
        #expect(try BaseX.decode(baseEncoded, as: .base36Upper) == testStringLeadingZero)

        #expect(try BaseX.decode("02LCPZO5YIKIDYNFL", as: .base36Upper) == testStringLeadingZero)
    }

    @Test func testBase58BTCLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base58BTC)
        #expect(try BaseX.decode(baseEncoded, as: .base58BTC) == testStringLeadingZero)

        #expect(try BaseX.decode("17paNL19xttacUY", as: .base58BTC) == testStringLeadingZero)
    }

    @Test func testBase58FlickrLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base58Flickr)
        #expect(try BaseX.decode(baseEncoded, as: .base58Flickr) == testStringLeadingZero)

        #expect(try BaseX.decode("17Pznk19XTTzBtx", as: .base58Flickr) == testStringLeadingZero)
    }

    // - MARK: Two Leading Zeros
    let testStringTwoLeadingZeros = "\0\0yes mani !"

    @Test func testBase10TwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base10Decimal)
        #expect(try BaseX.decode(baseEncoded, as: .base10Decimal) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("00573277761329450583662625", as: .base10Decimal) == testStringTwoLeadingZeros)
    }

    @Test func testBase16LowerTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base16Hex)
        #expect(try BaseX.decode(baseEncoded, as: .base16Hex) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("0000796573206d616e692021", as: .base16Hex) == testStringTwoLeadingZeros)
    }

    @Test func testBase16UpperTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base16HexUpper)
        #expect(try BaseX.decode(baseEncoded, as: .base16HexUpper) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("0000796573206D616E692021", as: .base16HexUpper) == testStringTwoLeadingZeros)
    }

    @Test func testBase36LowerTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base36)
        #expect(try BaseX.decode(baseEncoded, as: .base36) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("002lcpzo5yikidynfl", as: .base36) == testStringTwoLeadingZeros)
    }

    @Test func testBase36UpperTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base36Upper)
        #expect(try BaseX.decode(baseEncoded, as: .base36Upper) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("002LCPZO5YIKIDYNFL", as: .base36Upper) == testStringTwoLeadingZeros)
    }

    @Test func testBase58BTCTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base58BTC)
        #expect(try BaseX.decode(baseEncoded, as: .base58BTC) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("117paNL19xttacUY", as: .base58BTC) == testStringTwoLeadingZeros)
    }

    @Test func testBase58FlickrTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base58Flickr)
        #expect(try BaseX.decode(baseEncoded, as: .base58Flickr) == testStringTwoLeadingZeros)

        #expect(try BaseX.decode("117Pznk19XTTzBtx", as: .base58Flickr) == testStringTwoLeadingZeros)
    }

    /// Base16 decode previously returned an empty `Data` on invalid characters and
    /// mis-decoded odd-length input. It should now throw like every other base.
    @Test func testBase16DecodeRejectsInvalidInput() throws {
        #expect(throws: BaseX.BaseXError.invalidCharacter) {
            try BaseX.decode("zz", as: .base16Hex)
        }
        // Odd number of hex digits is not a whole number of bytes.
        #expect(throws: BaseX.BaseXError.invalidCharacter) {
            try BaseX.decode("abc", as: .base16Hex)
        }
        #expect(throws: BaseX.BaseXError.invalidCharacter) {
            try BaseX.decode("GG", as: .base16HexUpper)
        }
        // Valid hex still decodes.
        #expect(try BaseX.decode("796573206d616e692021", as: .base16Hex) == testString)
    }

    /// A valid custom alphabet should round-trip through the generic encode/decode path.
    @Test func testCustomAlphabetRoundTrips() throws {
        let alphabet = "0123456789abcdef"
        let encoded = try BaseX.encode(testString, into: .custom(alphabet))
        #expect(try BaseX.decode(encoded, as: .custom(alphabet)) == testString)
    }

    /// The uppercase hex path now uses a direct lookup table (no `.uppercased()` pass);
    /// it must still equal the lowercased output uppercased.
    @Test func testBase16UppercaseDirectTable() throws {
        let data = Data("Hello World".utf8)
        let upper = BaseX.encode(data, into: .base16HexUpper)
        let lower = BaseX.encode(data, into: .base16Hex)
        #expect(upper == lower.uppercased())
        #expect(upper == "48656C6C6F20576F726C64")
        #expect(try BaseX.decode(upper, as: .base16HexUpper) == data)
    }

    /// Compiles only if the public alphabet/error types are Sendable.
    @Test func testSendableConformances() {
        let _: any Sendable = BaseX.Alphabets.base58BTC
        let _: any Sendable = BaseX.Alphabets.custom("abc")
        let _: any Sendable = BaseX.BaseXError.invalidCharacter
    }

    /// Used to generate the example usage in our readme
    @Test(.disabled())
    func testBaseXExampleReadme() throws {
        let testString = "Hello World"

        print("/// Base10")
        let base10Encoded = try BaseX.encode(testString, into: .base10Decimal)
        print("let base10Encoded = try BaseX.encode(\"\(testString)\", into: .base10Decimal) // -> \(base10Encoded)")
        let base10Decoded: String = try BaseX.decode(base10Encoded, as: .base10Decimal)
        print(
            "let base10Decoded:String = try BaseX.decode(\"\(base10Encoded)\", as: .base10Decimal) // -> \(base10Decoded)"
        )
        print("")

        print("/// Base16 (HEX) Lowercased")
        let base16LEncoded = try BaseX.encode(testString, into: .base16Hex)
        print("let base16LEncoded = try BaseX.encode(\"\(testString)\", into: .base16Hex) // -> \(base16LEncoded)")
        let base16LDecoded: String = try BaseX.decode(base16LEncoded, as: .base16Hex)
        print(
            "let base16LDecoded:String = try BaseX.decode(\"\(base16LEncoded)\", as: .base16Hex) // -> \(base16LDecoded)"
        )
        print("")

        print("/// Base16 (HEX) Uppercased")
        let base16UEncoded = try BaseX.encode(testString, into: .base16HexUpper)
        print("let base16UEncoded = try BaseX.encode(\"\(testString)\", into: .base16HexUpper) // -> \(base16UEncoded)")
        let base16UDecoded: String = try BaseX.decode(base16UEncoded, as: .base16HexUpper)
        print(
            "let base16UDecoded:String = try BaseX.decode(\"\(base16UEncoded)\", as: .base16HexUpper) // -> \(base16UDecoded)"
        )
        print("")

        print("/// Base36 Lowercased")
        let base36LEncoded = try BaseX.encode(testString, into: .base36)
        print("let base36LEncoded = try BaseX.encode(\"\(testString)\", into: .base36) // -> \(base36LEncoded)")
        let base36LDecoded: String = try BaseX.decode(base36LEncoded, as: .base36)
        print(
            "let base36LDecoded:String = try BaseX.decode(\"\(base36LEncoded)\", as: .base36) // -> \(base36LDecoded)"
        )
        print("")

        print("/// Base36 Uppercased")
        let base36UEncoded = try BaseX.encode(testString, into: .base36Upper)
        print("let base36UEncoded = try BaseX.encode(\"\(testString)\", into: .base36Upper) // -> \(base36UEncoded)")
        let base36UDecoded: String = try BaseX.decode(base36UEncoded, as: .base36Upper)
        print(
            "let base36UDecoded:String = try BaseX.decode(\"\(base36UEncoded)\", as: .base36Upper) // -> \(base36UDecoded)"
        )
        print("")

        print("/// Base58BTC")
        let base58BTCEncoded = try BaseX.encode(testString, into: .base58BTC)
        print("let base58BTCEncoded = try BaseX.encode(\"\(testString)\", into: .base58BTC) // -> \(base58BTCEncoded)")
        let base58BTCDecoded: String = try BaseX.decode(base58BTCEncoded, as: .base58BTC)
        print(
            "let base58BTCDecoded:String = try BaseX.decode(\"\(base58BTCEncoded)\", as: .base58BTC) // -> \(base58BTCDecoded)"
        )
        print("")

        print("/// Base58Flickr")
        let base58FlickrEncoded = try BaseX.encode(testString, into: .base58Flickr)
        print(
            "let base58FlickrEncoded = try BaseX.encode(\"\(testString)\", into: .base58Flickr) // -> \(base58FlickrEncoded)"
        )
        let base58FlickrDecoded: String = try BaseX.decode(base58FlickrEncoded, as: .base58Flickr)
        print(
            "let base58FlickrDecoded:String = try BaseX.decode(\"\(base58FlickrEncoded)\", as: .base58Flickr) // -> \(base58FlickrDecoded)"
        )
    }
}
