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

@testable import Base32

final class Base32Tests: XCTestCase {

    let debug: Bool = false

    let Base32StandardTests: [String: String] = [
        "": "",
        "f": "MY======",
        "fo": "MZXQ====",
        "foo": "MZXW6===",
        "foob": "MZXW6YQ=",
        "fooba": "MZXW6YTB",
        "foobar": "MZXW6YTBOI======",
        "yes mani !": "PFSXGIDNMFXGSIBB",
        "hello world": "NBSWY3DPEB3W64TMMQ======",
        "Decentralize everything!!": "IRSWGZLOORZGC3DJPJSSAZLWMVZHS5DINFXGOIJB",
    ]

    /// Standard Base32 Encoding (uppercase with padding)
    func testEncodeStandard() {
        if debug { print("-- Base32 Standard (Uppercase with Padding) --") }
        for test in Base32StandardTests.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key)
            if debug { print("Base32.encode(\"\(test.key)\") => \"\(encoded)\"") }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// Standard Base32 Decoding (uppercase with padding)
    func testDecodeStandard() {
        for test in Base32StandardTests.sorted(by: { $0.key.count < $1.key.count }) {
            do {
                let d = try Base32.decode(test.value)
                let str = String(data: d, encoding: .ascii)
                if debug { print("Base32.decode(\"\(test.value)\") => \"\(str ?? "nil")\"") }
                XCTAssertEqual(str, test.key)
            } catch {
                print("Error: \(error)")
                XCTFail(error.localizedDescription)
            }
        }
    }

    let Base32StandardTestsLowercaseWithPadding: [String: String] = [
        "": "",
        "f": "my======",
        "fo": "mzxq====",
        "foo": "mzxw6===",
        "foob": "mzxw6yq=",
        "fooba": "mzxw6ytb",
        "foobar": "mzxw6ytboi======",
        "yes mani !": "pfsxgidnmfxgsibb",
        "hello world": "nbswy3dpeb3w64tmmq======",
        "Decentralize everything!!": "irswgzloorzgc3djpjssazlwmvzhs5dinfxgoijb",
    ]
    /// Standard Base32 Encoding (lowercase with padding)
    func testEncodeStandardLowercaseWithPadding() {
        if debug { print("-- Base32 Standard (Lowercase with Padding) --") }
        for test in Base32StandardTestsLowercaseWithPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.lower), .pad(true))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.lower), .pad(true)) => \"\(encoded)\"")
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    //    func testLowercasedPadded() {
    //        XCTAssertEqual(Base32.encode("", options: .letterCase(.lower)),       ""                 )
    //        XCTAssertEqual(Base32.encode("f", options: .letterCase(.lower)),      "my======"         )
    //        XCTAssertEqual(Base32.encode("fo", options: .letterCase(.lower)),     "mzxq===="         )
    //        XCTAssertEqual(Base32.encode("foo", options: .letterCase(.lower)),    "mzxw6==="         )
    //        XCTAssertEqual(Base32.encode("foob", options: .letterCase(.lower)),   "mzxw6yq="         )
    //        XCTAssertEqual(Base32.encode("fooba", options: .letterCase(.lower)),  "mzxw6ytb"         )
    //        XCTAssertEqual(Base32.encode("foobar", options: .letterCase(.lower)), "mzxw6ytboi======" )
    //
    //        XCTAssertEqual(Base32.encode("yes mani !", options: .letterCase(.lower)),                "pfsxgidnmfxgsibb"                        )
    //        XCTAssertEqual(Base32.encode("hello world", options: .letterCase(.lower)),               "nbswy3dpeb3w64tmmq======"                )
    //        XCTAssertEqual(Base32.encode("Decentralize everything!!", options: .letterCase(.lower)), "irswgzloorzgc3djpjssazlwmvzhs5dinfxgoijb")
    //    }

    let Base32StandardTestsUppercaseNoPadding: [String: String] = [
        "": "",
        "f": "MY",
        "fo": "MZXQ",
        "foo": "MZXW6",
        "foob": "MZXW6YQ",
        "fooba": "MZXW6YTB",
        "foobar": "MZXW6YTBOI",
        "yes mani !": "PFSXGIDNMFXGSIBB",
        "hello world": "NBSWY3DPEB3W64TMMQ",
        "Decentralize everything!!": "IRSWGZLOORZGC3DJPJSSAZLWMVZHS5DINFXGOIJB",
    ]

    /// Standard Base32 Encoding (uppercase without padding)
    func testEncodeStandardUppercaseWithoutPadding() {
        if debug { print("-- Base32 Standard (Uppercase without Padding) --") }
        for test in Base32StandardTestsUppercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.upper), .pad(false))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.upper), .pad(false)) => \"\(encoded)\"")
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    let Base32StandardTestsLowercaseNoPadding: [String: String] = [
        "": "",
        "f": "my",
        "fo": "mzxq",
        "foo": "mzxw6",
        "foob": "mzxw6yq",
        "fooba": "mzxw6ytb",
        "foobar": "mzxw6ytboi",
        "yes mani !": "pfsxgidnmfxgsibb",
        "hello world": "nbswy3dpeb3w64tmmq",
        "Decentralize everything!!": "irswgzloorzgc3djpjssazlwmvzhs5dinfxgoijb",
    ]

    /// Standard Base32 Encoding (lowercase without padding)
    func testEncodeStandardLowercaseWithoutPadding() {
        if debug { print("-- Base32 Standard (Lowercase without Padding) --") }
        for test in Base32StandardTestsLowercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.lower), .pad(false))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.lower), .pad(false)) => \"\(encoded)\"")
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    // MARK: - Hex Tests
    let Base32HexTests: [String: String] = [
        "": "",
        "f": "CO======",
        "fo": "CPNG====",
        "foo": "CPNMU===",
        "foob": "CPNMUOG=",
        "fooba": "CPNMUOJ1",
        "foobar": "CPNMUOJ1E8======",
        "yes mani !": "F5IN683DC5N6I811",
        "hello world": "D1IMOR3F41RMUSJCCG======",
        "Decentralize everything!!": "8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891",
    ]

    /// Hex Base32 Encoding (uppercase with padding)
    func testEncodeHex() {
        if debug { print("-- Base32 Extended Hex (Uppercase with Padding) --") }
        for test in Base32HexTests.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex)
            if debug { print("Base32.encode(\"\(test.key)\", variant: .hex) => \"\(encoded)\"") }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// Hex Base32 Decoding (uppercase with padding)
    func testDecodeHex() {
        for test in Base32HexTests.sorted(by: { $0.key.count < $1.key.count }) {
            do {
                let d = try Base32.decode(test.value, variant: .hex)
                let str = String(data: d, encoding: .ascii)
                if debug { print("Base32.decode(\"\(test.value)\", variant: .hex) => \"\(str ?? "nil")\"") }
                XCTAssertEqual(str, test.key)
            } catch {
                print("Error: \(error)")
                XCTFail(error.localizedDescription)
            }
        }
    }

    let Base32HexTestsLowercaseWithPadding: [String: String] = [
        "": "",
        "f": "co======",
        "fo": "cpng====",
        "foo": "cpnmu===",
        "foob": "cpnmuog=",
        "fooba": "cpnmuoj1",
        "foobar": "cpnmuoj1e8======",
        "yes mani !": "f5in683dc5n6i811",
        "hello world": "d1imor3f41rmusjccg======",
        "Decentralize everything!!": "8him6pbeehp62r39f9ii0pbmclp7it38d5n6e891",
    ]

    /// Hex Base32 Encoding (uppercase without padding)
    func testEncodeHexLowercaseWithPadding() {
        if debug { print("-- Base32 Extended Hex (Lowercase with Padding) --") }
        for test in Base32HexTestsLowercaseWithPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.lower), .pad(true))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.lower), .pad(true)) => \"\(encoded)\""
                )
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    let Base32HexTestsUppercaseNoPadding: [String: String] = [
        "": "",
        "f": "CO",
        "fo": "CPNG",
        "foo": "CPNMU",
        "foob": "CPNMUOG",
        "fooba": "CPNMUOJ1",
        "foobar": "CPNMUOJ1E8",
        "yes mani !": "F5IN683DC5N6I811",
        "hello world": "D1IMOR3F41RMUSJCCG",
        "Decentralize everything!!": "8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891",
    ]

    /// Hex Base32 Encoding (uppercase without padding)
    func testEncodeHexUppercaseWithoutPadding() {
        if debug { print("-- Base32 Extended Hex (Uppercase without Padding) --") }
        for test in Base32HexTestsUppercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.upper), .pad(false))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.upper), .pad(false)) => \"\(encoded)\""
                )
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    let Base32HexTestsLowercaseNoPadding: [String: String] = [
        "": "",
        "f": "co",
        "fo": "cpng",
        "foo": "cpnmu",
        "foob": "cpnmuog",
        "fooba": "cpnmuoj1",
        "foobar": "cpnmuoj1e8",
        "yes mani !": "f5in683dc5n6i811",
        "hello world": "d1imor3f41rmusjccg",
        "Decentralize everything!!": "8him6pbeehp62r39f9ii0pbmclp7it38d5n6e891",
    ]

    /// Hex Base32 Encoding (lowercase without padding)
    func testEncodeHexLowercaseWithoutPadding() {
        if debug { print("-- Base32 Extended Hex (Lowercase without Padding) --") }
        for test in Base32HexTestsLowercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.lower), .pad(false))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.lower), .pad(false)) => \"\(encoded)\""
                )
            }
            XCTAssertEqual(encoded, test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    // MARK: - Z Tests
    func testZ() {
        //XCTAssertEqual(Base32.encode("".data(using: .ascii)!, variant: .z),       ""                 )
        //XCTAssertEqual(Base32.encode("f".data(using: .ascii)!, variant: .z),      "CO======"         )
        //XCTAssertEqual(Base32.encode("fo".data(using: .ascii)!, variant: .z),     "CPNG===="         )
        //XCTAssertEqual(Base32.encode("foo".data(using: .ascii)!, variant: .z),    "CPNMU==="         )
        //XCTAssertEqual(Base32.encode("foob".data(using: .ascii)!, variant: .z),   "CPNMUOG="         )
        //XCTAssertEqual(Base32.encode("fooba".data(using: .ascii)!, variant: .z),  "CPNMUOJ1"         )
        //XCTAssertEqual(Base32.encode("foobar".data(using: .ascii)!, variant: .z), "CPNMUOJ1E8======" )

        XCTAssertEqual(
            Base32.encode("yes mani !", variant: .z, options: .letterCase(.lower), .pad(false)),
            "xf1zgedpcfzg1ebb"
        )
        XCTAssertEqual(
            Base32.encode("\0\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false), .nullChar(.drop)),
            "xf1zgedpcfzg1ebb"
        )
        XCTAssertEqual(
            Base32.encode("\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false)),
            "ybhskh3ypiosh4jyrr"
        )
        XCTAssertEqual(
            Base32.encode("\0\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false)),
            "yyy813murbssn5ujryoo"
        )
        XCTAssertEqual(
            Base32.encode("hello world", variant: .z, options: .letterCase(.lower), .pad(false)),
            "pb1sa5dxrb5s6hucco"
        )
        XCTAssertEqual(
            Base32.encode("Decentralize everything!!", variant: .z, options: .letterCase(.lower), .pad(false)),
            "et1sg3mqqt3gn5djxj11y3msci3817depfzgqejb"
        )

        XCTAssertEqual(try? Base32.decode("Xf1zgeDpcfzG1ebB", variant: .z), "yes mani !".data(using: .ascii))
        //XCTAssertEqual(Base32.encode("hello world".data(using: .ascii)!, variant: .z), "D1IMOR3F41RMUSJCCG======"                )
        //XCTAssertEqual(Base32.encode("Decentralize everything!!".data(using: .ascii)!, variant: .z), "8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891")
    }

    static var allTests = [
        ("testEncodeStandard", testEncodeStandard),
        ("testDecodeStandard", testDecodeStandard),
        ("testEncodeStandardLowercaseWithPadding", testEncodeStandardLowercaseWithPadding),
        ("testEncodeStandardUppercaseWithoutPadding", testEncodeStandardUppercaseWithoutPadding),
        ("testEncodeStandardLowercaseWithoutPadding", testEncodeStandardLowercaseWithoutPadding),

        ("testEncodeHex", testEncodeHex),
        ("testDecodeHex", testDecodeHex),
        ("testEncodeHexLowercaseWithPadding", testEncodeHexLowercaseWithPadding),
        ("testEncodeHexUppercaseWithoutPadding", testEncodeHexUppercaseWithoutPadding),
        ("testEncodeHexLowercaseWithoutPadding", testEncodeHexLowercaseWithoutPadding),

        ("testZ", testZ),
    ]
}
