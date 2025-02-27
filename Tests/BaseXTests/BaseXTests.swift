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

@testable import BaseX

final class BaseXTests: XCTestCase {
    let testString = "yes mani !"

    func testBase10() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base10Decimal)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base10Decimal), testString)

        XCTAssertEqual(try BaseX.decode("573277761329450583662625", as: .base10Decimal), testString)
    }

    func testBase16Lower() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base16Hex)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16Hex), testString)

        XCTAssertEqual(try BaseX.decode("796573206d616e692021", as: .base16Hex), testString)
    }

    func testBase16Upper() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base16HexUpper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16HexUpper), testString)

        XCTAssertEqual(try BaseX.decode("796573206D616E692021", as: .base16HexUpper), testString)
    }

    func testBase36Lower() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base36)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36), testString)

        XCTAssertEqual(try BaseX.decode("2lcpzo5yikidynfl", as: .base36), testString)
    }

    func testBase36Upper() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base36Upper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36Upper), testString)

        XCTAssertEqual(try BaseX.decode("2LCPZO5YIKIDYNFL", as: .base36Upper), testString)
    }

    func testBase58BTC() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base58BTC)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58BTC), testString)

        XCTAssertEqual(try BaseX.decode("7paNL19xttacUY", as: .base58BTC), testString)
    }

    func testBase58Flickr() throws {
        let baseEncoded = try BaseX.encode(testString, into: .base58Flickr)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58Flickr), testString)

        XCTAssertEqual(try BaseX.decode("7Pznk19XTTzBtx", as: .base58Flickr), testString)
    }

    // - MARK: Leading Zero
    let testStringLeadingZero = "\0yes mani !"

    func testBase10LeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base10Decimal)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base10Decimal), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("0573277761329450583662625", as: .base10Decimal), testStringLeadingZero)
    }

    func testBase16LowerLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base16Hex)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16Hex), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("00796573206d616e692021", as: .base16Hex), testStringLeadingZero)
    }

    func testBase16AllZeros() throws {
        /// Defaults to 32 bytes
        let zeros = [UInt8](repeating: 0, count: 32)
        let baseEncoded = BaseX.encode(Data(zeros), into: .base16Hex)
        let target = "0000000000000000000000000000000000000000000000000000000000000000"

        XCTAssertEqual(zeros.count, 32)
        XCTAssertEqual(
            zeros,
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        )
        XCTAssertEqual(target.count, 64)
        XCTAssertEqual(baseEncoded.count, 64)
        XCTAssertEqual(baseEncoded, target)
    }

    func testBase16UpperLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base16HexUpper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16HexUpper), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("00796573206D616E692021", as: .base16HexUpper), testStringLeadingZero)
    }

    func testBase36LowerLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base36)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("02lcpzo5yikidynfl", as: .base36), testStringLeadingZero)
    }

    func testBase36UpperLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base36Upper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36Upper), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("02LCPZO5YIKIDYNFL", as: .base36Upper), testStringLeadingZero)
    }

    func testBase58BTCLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base58BTC)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58BTC), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("17paNL19xttacUY", as: .base58BTC), testStringLeadingZero)
    }

    func testBase58FlickrLeadingZero() throws {
        let baseEncoded = try BaseX.encode(testStringLeadingZero, into: .base58Flickr)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58Flickr), testStringLeadingZero)

        XCTAssertEqual(try BaseX.decode("17Pznk19XTTzBtx", as: .base58Flickr), testStringLeadingZero)
    }

    // - MARK: Two Leading Zeros
    let testStringTwoLeadingZeros = "\0\0yes mani !"

    func testBase10TwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base10Decimal)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base10Decimal), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("00573277761329450583662625", as: .base10Decimal), testStringTwoLeadingZeros)
    }

    func testBase16LowerTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base16Hex)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16Hex), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("0000796573206d616e692021", as: .base16Hex), testStringTwoLeadingZeros)
    }

    func testBase16UpperTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base16HexUpper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base16HexUpper), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("0000796573206D616E692021", as: .base16HexUpper), testStringTwoLeadingZeros)
    }

    func testBase36LowerTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base36)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("002lcpzo5yikidynfl", as: .base36), testStringTwoLeadingZeros)
    }

    func testBase36UpperTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base36Upper)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base36Upper), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("002LCPZO5YIKIDYNFL", as: .base36Upper), testStringTwoLeadingZeros)
    }

    func testBase58BTCTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base58BTC)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58BTC), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("117paNL19xttacUY", as: .base58BTC), testStringTwoLeadingZeros)
    }

    func testBase58FlickrTwoLeadingZeros() throws {
        let baseEncoded = try BaseX.encode(testStringTwoLeadingZeros, into: .base58Flickr)
        XCTAssertEqual(try BaseX.decode(baseEncoded, as: .base58Flickr), testStringTwoLeadingZeros)

        XCTAssertEqual(try BaseX.decode("117Pznk19XTTzBtx", as: .base58Flickr), testStringTwoLeadingZeros)
    }

    /// Used to generate the example usage in our readme
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
