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

@testable import Base32

@Suite("Base 32 Tests")
struct Base32Tests {

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
    @Test func testEncodeStandard() {
        if debug { print("-- Base32 Standard (Uppercase with Padding) --") }
        for test in Base32StandardTests.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key)
            if debug { print("Base32.encode(\"\(test.key)\") => \"\(encoded)\"") }
            #expect(encoded == test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// Standard Base32 Decoding (uppercase with padding)
    @Test func testDecodeStandard() throws {
        for test in Base32StandardTests.sorted(by: { $0.key.count < $1.key.count }) {
            do {
                let d = try Base32.decode(test.value)
                let str = String(data: d, encoding: .ascii)
                if debug { print("Base32.decode(\"\(test.value)\") => \"\(str ?? "nil")\"") }
                #expect(str == test.key)
            } catch {
                if debug { print("Error: \(error.localizedDescription)") }
                throw error
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
    @Test func testEncodeStandardLowercaseWithPadding() {
        if debug { print("-- Base32 Standard (Lowercase with Padding) --") }
        for test in Base32StandardTestsLowercaseWithPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.lower), .pad(true))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.lower), .pad(true)) => \"\(encoded)\"")
            }
            #expect(encoded == test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

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
    @Test func testEncodeStandardUppercaseWithoutPadding() {
        if debug { print("-- Base32 Standard (Uppercase without Padding) --") }
        for test in Base32StandardTestsUppercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.upper), .pad(false))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.upper), .pad(false)) => \"\(encoded)\"")
            }
            #expect(encoded == test.value)
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
    @Test func testEncodeStandardLowercaseWithoutPadding() {
        if debug { print("-- Base32 Standard (Lowercase without Padding) --") }
        for test in Base32StandardTestsLowercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, options: .letterCase(.lower), .pad(false))
            if debug {
                print("Base32.encode(\"\(test.key)\", options: .letterCase(.lower), .pad(false)) => \"\(encoded)\"")
            }
            #expect(encoded == test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// Non-ASCII input previously trapped because `encode(String)` force-unwrapped
    /// `data(using: .ascii)`. It now encodes via UTF-8 and round-trips.
    @Test func testEncodeNonASCIIDoesNotCrash() throws {
        let input = "café 🚀"
        let encoded = Base32.encode(input)
        let decoded = try Base32.decode(encoded)
        #expect(decoded == Data(input.utf8))
    }

    @Test func testDecodeEmptyReturnsEmptyData() throws {
        #expect(try Base32.decode("") == Data())
    }

    @Test func testDecodeStandardRejectsOutOfRangeLetters() {
        for c in ["0", "1", "8", "9", "!", "&", "#"] {
            #expect(throws: Base32.Error.nonAlphabetCharacter, "expected '\(c)' to be rejected") {
                try Base32.decode(String(repeating: c, count: 8), variant: .standard)
            }
        }
        // Boundary: '7' is the highest valid standard letter and must still be accepted.
        #expect((try? Base32.decode("77777777", variant: .standard)) == Data(repeating: 0xFF, count: 5))
        // Boundary: 'A' is the lowest valid standard letter and must still be accepted.
        #expect((try? Base32.decode("AAAAAAAA", variant: .standard)) == Data(repeating: 0x00, count: 5))
        #expect((try? Base32.decode("aaaaaaaa", variant: .standard)) == Data(repeating: 0x00, count: 5))
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
    @Test func testEncodeHex() {
        if debug { print("-- Base32 Extended Hex (Uppercase with Padding) --") }
        for test in Base32HexTests.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex)
            if debug { print("Base32.encode(\"\(test.key)\", variant: .hex) => \"\(encoded)\"") }
            #expect(encoded == test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// Hex Base32 Decoding (uppercase with padding)
    @Test func testDecodeHex() throws {
        for test in Base32HexTests.sorted(by: { $0.key.count < $1.key.count }) {
            do {
                let d = try Base32.decode(test.value, variant: .hex)
                let str = String(data: d, encoding: .ascii)
                if debug { print("Base32.decode(\"\(test.value)\", variant: .hex) => \"\(str ?? "nil")\"") }
                #expect(str == test.key)
            } catch {
                if debug { print("Error: \(error.localizedDescription)") }
                throw error
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
    @Test func testEncodeHexLowercaseWithPadding() {
        if debug { print("-- Base32 Extended Hex (Lowercase with Padding) --") }
        for test in Base32HexTestsLowercaseWithPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.lower), .pad(true))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.lower), .pad(true)) => \"\(encoded)\""
                )
            }
            #expect(encoded == test.value)
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
    @Test func testEncodeHexUppercaseWithoutPadding() {
        if debug { print("-- Base32 Extended Hex (Uppercase without Padding) --") }
        for test in Base32HexTestsUppercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.upper), .pad(false))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.upper), .pad(false)) => \"\(encoded)\""
                )
            }
            #expect(encoded == test.value)
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
    @Test func testEncodeHexLowercaseWithoutPadding() {
        if debug { print("-- Base32 Extended Hex (Lowercase without Padding) --") }
        for test in Base32HexTestsLowercaseNoPadding.sorted(by: { $0.key.count < $1.key.count }) {
            let encoded = Base32.encode(test.key, variant: .hex, options: .letterCase(.lower), .pad(false))
            if debug {
                print(
                    "Base32.encode(\"\(test.key)\", variant: .hex, options: .letterCase(.lower), .pad(false)) => \"\(encoded)\""
                )
            }
            #expect(encoded == test.value)
        }
        if debug { print("-----------------------------------------------------") }
    }

    /// The Base32 extended-hex alphabet is '0'-'9' and 'A'-'V' (values 0-31).
    /// Characters 'W'-'Z' (and lowercase) must be rejected; previously the decoder's
    /// guard `65...90` / `97...122` accepted them and silently produced wrong bytes.
    @Test func testDecodeHexRejectsOutOfRangeLetters() {
        for c in ["W", "X", "Y", "Z", "w", "x", "y", "z"] {
            #expect(throws: Base32.Error.nonAlphabetCharacter, "expected '\(c)' to be rejected") {
                try Base32.decode(String(repeating: c, count: 8), variant: .hex)
            }
        }
        // Boundary: 'V' / 'v' (value 31) is the highest valid hex letter and must still be accepted.
        #expect((try? Base32.decode("VVVVVVVV", variant: .hex)) == Data(repeating: 0xFF, count: 5))
        #expect((try? Base32.decode("vvvvvvvv", variant: .hex)) == Data(repeating: 0xFF, count: 5))
    }

    // MARK: - Z Tests
    @Test func testZ() {
        #expect(
            Base32.encode("yes mani !", variant: .z, options: .letterCase(.lower), .pad(false))
                == "xf1zgedpcfzg1ebb"
        )
        #expect(
            Base32.encode("\0\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false), .nullChar(.drop))
                == "xf1zgedpcfzg1ebb"
        )
        #expect(
            Base32.encode("\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false))
                == "ybhskh3ypiosh4jyrr"
        )
        #expect(
            Base32.encode("\0\0yes mani !", variant: .z, options: .letterCase(.lower), .pad(false))
                == "yyy813murbssn5ujryoo"
        )
        #expect(
            Base32.encode("hello world", variant: .z, options: .letterCase(.lower), .pad(false))
                == "pb1sa5dxrb5s6hucco"
        )
        #expect(
            Base32.encode("Decentralize everything!!", variant: .z, options: .letterCase(.lower), .pad(false))
                == "et1sg3mqqt3gn5djxj11y3msci3817depfzgqejb"
        )

        #expect((try? Base32.decode("Xf1zgeDpcfzG1ebB", variant: .z)) == "yes mani !".data(using: .ascii))
        //#expect(Base32.encode("hello world".data(using: .ascii)!, variant: .z) == "D1IMOR3F41RMUSJCCG======"                )
        //#expect(Base32.encode("Decentralize everything!!".data(using: .ascii)!, variant: .z) == "8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891")
    }

    @Test func testDecodeZRejectsOutOfRangeLetters() {
        for c in ["l", "L", "v", "V", "0", "2", "#"] {
            #expect(throws: Base32.Error.nonAlphabetCharacter, "expected '\(c)' to be rejected") {
                try Base32.decode(String(repeating: c, count: 8), variant: .z)
            }
        }
        // Boundary: '9' is the highest valid z letter and must still be accepted.
        #expect((try? Base32.decode("99999999", variant: .z)) == Data(repeating: 0xFF, count: 5))
        // Boundary: 'y' is the lowest valid z letter and must still be accepted.
        #expect((try? Base32.decode("yyyyyyyy", variant: .z)) == Data(repeating: 0x00, count: 5))
        #expect((try? Base32.decode("YYYYYYYY", variant: .z)) == Data(repeating: 0x00, count: 5))
    }

    /// The Data convenience wrappers mirror the enum's encode/decode, including variants.
    @Test func testDataConvenienceRoundTrip() throws {
        let data = Data("hello world".utf8)
        let encoded = data.base32Encoded()
        #expect(encoded == Base32.encode("hello world"))
        #expect(try Data(base32Encoded: encoded) == data)

        let hex = data.base32Encoded(variant: .hex)
        #expect(try Data(base32Encoded: hex, variant: .hex) == data)
    }

    /// Compiles only if the public option/variant/error types are Sendable.
    @Test func testSendableConformances() {
        let _: any Sendable = Base32.Variant.standard
        let _: any Sendable = Base32Options.pad(true)
        let _: any Sendable = LetterCase.lower
        let _: any Sendable = Base32.Error.strayBits
    }
}
