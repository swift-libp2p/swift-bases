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

@testable import Base64

@Suite("Base 64 Tests")
struct Base64Tests {

    // MARK: - Multibase vectors ("yes mani !")
    //
    // From the multiformats/multibase test vectors (prefix char stripped, since the
    // multibase prefix is not this layer's responsibility):
    //   m  base64        -> eWVzIG1hbmkgIQ
    //   M  base64pad     -> eWVzIG1hbmkgIQ==
    //   u  base64url     -> eWVzIG1hbmkgIQ
    //   U  base64urlpad  -> eWVzIG1hbmkgIQ==
    let plaintext = "yes mani !"

    @Test func testEncodeMultibaseVariants() {
        #expect(Base64.encode(plaintext, variant: .standard, pad: false) == "eWVzIG1hbmkgIQ")
        #expect(Base64.encode(plaintext, variant: .standard, pad: true) == "eWVzIG1hbmkgIQ==")
        #expect(Base64.encode(plaintext, variant: .url, pad: false) == "eWVzIG1hbmkgIQ")
        #expect(Base64.encode(plaintext, variant: .url, pad: true) == "eWVzIG1hbmkgIQ==")
    }

    @Test func testDecodeMultibaseVariants() throws {
        #expect(try Base64.decodeToString("eWVzIG1hbmkgIQ", variant: .standard) == plaintext)
        #expect(try Base64.decodeToString("eWVzIG1hbmkgIQ==", variant: .standard) == plaintext)
        #expect(try Base64.decodeToString("eWVzIG1hbmkgIQ", variant: .url) == plaintext)
        #expect(try Base64.decodeToString("eWVzIG1hbmkgIQ==", variant: .url) == plaintext)
    }

    /// The previously-broken case: an unpadded *standard* string could not be decoded
    /// because Foundation's decoder requires padding. Decoding is now padding-tolerant.
    @Test func testDecodeUnpaddedStandard() throws {
        #expect(try Base64.decode("eWVzIG1hbmkgIQ", variant: .standard) == Data(plaintext.utf8))
    }

    // MARK: - URL alphabet differs from standard

    /// 0xFF * 3 encodes to four value-63 sextets: `/` in standard, `_` in URL-safe.
    @Test func testUrlAlphabetSlash() throws {
        let data = Data(repeating: 0xFF, count: 3)
        #expect(Base64.encode(data, variant: .standard, pad: false) == "////")
        #expect(Base64.encode(data, variant: .url, pad: false) == "____")
        #expect(try Base64.decode("////", variant: .standard) == data)
        #expect(try Base64.decode("____", variant: .url) == data)
    }

    /// 0xFB starts with a value-62 sextet: `+` in standard, `-` in URL-safe.
    @Test func testUrlAlphabetPlus() throws {
        let data = Data([0xFB])
        #expect(Base64.encode(data, variant: .standard, pad: true) == "+w==")
        #expect(Base64.encode(data, variant: .url, pad: true) == "-w==")
        #expect(try Base64.decode("-w==", variant: .url) == data)
    }

    // MARK: - Round-trips & edge cases

    @Test func testRoundTripAllVariants() throws {
        let payloads: [Data] = [
            Data(),
            Data([0x00]),
            Data([0x00, 0x00, 0x00]),
            Data("Decentralize everything!!".utf8),
            Data((0...255).map { UInt8($0) }),
        ]
        for data in payloads {
            for variant in [Base64.Variant.standard, .url] {
                for pad in [true, false] {
                    let encoded = Base64.encode(data, variant: variant, pad: pad)
                    #expect(try Base64.decode(encoded, variant: variant) == data)
                }
            }
        }
    }

    @Test func testDecodeEmptyReturnsEmptyData() throws {
        #expect(try Base64.decode("", variant: .standard) == Data())
        #expect(try Base64.decode("", variant: .url) == Data())
    }

    @Test func testDecodeInvalidThrows() {
        #expect(throws: Base64.Error.invalidCharacter) {
            try Base64.decode("****", variant: .standard)
        }
        // `-` and `_` are not valid in the standard alphabet.
        #expect(throws: Base64.Error.invalidCharacter) {
            try Base64.decode("____", variant: .standard)
        }
    }

    // MARK: - Data/String extension surface

    @Test func testDataURLInitThrowing() throws {
        let data = Data(repeating: 0xFF, count: 3)
        #expect(try Data(base64URLEncoded: "____") == data)
        #expect(try Data(base64URLEncoded: Data("____".utf8)) == data)
    }

    /// Compiles only if the public variant/error types are Sendable.
    @Test func testSendableConformances() {
        let _: any Sendable = Base64.Variant.url
        let _: any Sendable = Base64.Error.invalidCharacter
    }
}
