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

@testable import Base32

/// Covers the byte-native API added in 0.4.0. `Base32Tests` covers the same ground through
/// the deprecated `Data`/`String` surface.
@Suite("Base 32 Byte Tests")
struct Base32ByteTests {

    let plaintext = Array("yes mani !".utf8)

    /// The multibase test vectors for "yes mani !", with the prefix character stripped.
    @Test func testEncodesMultibaseVectors() {
        #expect(
            Base32.encodedString(plaintext, letterCase: .lower, pad: .unpadded)
                == "pfsxgidnmfxgsibb"
        )
        #expect(
            Base32.encodedString(plaintext, letterCase: .upper, pad: .unpadded)
                == "PFSXGIDNMFXGSIBB"
        )
        #expect(
            Base32.encodedString(plaintext, variant: .hex, letterCase: .lower, pad: .unpadded)
                == "f5in683dc5n6i811"
        )
        #expect(
            Base32.encodedString(plaintext, variant: .z, pad: .unpadded)
                == "xf1zgedpcfzg1ebb"
        )
    }

    /// Omitting `letterCase` uses the variant's preferred case:
    /// - upper for standard and hex.
    /// - lower for z.
    @Test func testNaturalCase() {
        #expect(Base32.encodedString(plaintext, pad: .unpadded) == "PFSXGIDNMFXGSIBB")
        #expect(Base32.encodedString(plaintext, variant: .hex, pad: .unpadded) == "F5IN683DC5N6I811")
        #expect(Base32.encodedString(plaintext, variant: .z, pad: .unpadded) == "xf1zgedpcfzg1ebb")
        #expect(Base32.Variant.standard.naturalCase == .upper)
        #expect(Base32.Variant.hex.naturalCase == .upper)
        #expect(Base32.Variant.z.naturalCase == .lower)
    }

    @Test func testPadding() {
        #expect(Base32.encodedString(Array("f".utf8)) == "MY======")
        #expect(Base32.encodedString(Array("f".utf8), pad: .unpadded) == "MY")
        #expect(Base32.encodedString(Array("foob".utf8)) == "MZXW6YQ=")
        #expect(Base32.encodedString(Array("foob".utf8), pad: .unpadded) == "MZXW6YQ")
        // A whole number of blocks is never padded.
        #expect(Base32.encodedString(Array("fooba".utf8)) == "MZXW6YTB")
    }

    /// Decoding is case-insensitive for all three variants, so the multibase layer no
    /// longer needs to case-convert the input first.
    @Test func testDecodingIsCaseInsensitive() throws {
        #expect(try Base32.decode("pfsxgidnmfxgsibb") == plaintext)
        #expect(try Base32.decode("PFSXGIDNMFXGSIBB") == plaintext)
        #expect(try Base32.decode("PfSxGiDnMfXgSiBb") == plaintext)
        #expect(try Base32.decode("f5in683dc5n6i811", variant: .hex) == plaintext)
        #expect(try Base32.decode("F5IN683DC5N6I811", variant: .hex) == plaintext)
        #expect(try Base32.decode("xf1zgedpcfzg1ebb", variant: .z) == plaintext)
        #expect(try Base32.decode("XF1ZGEDPCFZG1EBB", variant: .z) == plaintext)
    }

    /// A slice encodes without first being copied into an array.
    @Test func testEncodesASliceWithoutCopying() {
        let padded = Array("<<>>".utf8) + plaintext
        #expect(
            Base32.encodedString(padded.dropFirst(4), letterCase: .lower, pad: .unpadded)
                == "pfsxgidnmfxgsibb"
        )
    }

    @Test func testEmptyInput() throws {
        #expect(Base32.encode([UInt8]()) == [UInt8]())
        #expect(try Base32.decode("") == [UInt8]())
        #expect(try Base32.decode("========") == [UInt8]())
    }

    @Test func testRoundTripsEveryBlockRemainderInEveryVariant() throws {
        let bytes = (0...255).map { UInt8($0) }
        for variant in [Base32.Variant.standard, .hex, .z] {
            for length in 0...16 {
                let payload = Array(bytes.prefix(length))
                for pad in [PadOption.padded, .unpadded] {
                    for letterCase in [LetterCase.upper, .lower] {
                        let encoded = Base32.encode(payload, variant: variant, letterCase: letterCase, pad: pad)
                        #expect(try Base32.decode(encoded, variant: variant) == payload)
                    }
                }
            }
        }
    }

    @Test func testRejectsCharactersOutsideTheAlphabet() {
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base32.decode(Array("MZXW6YT!".utf8)) }
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base32.decode(Array("00000000".utf8)) }
        // A character after the padding is malformed too.
        #expect(throws: BasesError.nonAlphabetCharacter) { try Base32.decode(Array("MY======A".utf8)) }
    }

    @Test func testRejectsIncompleteBlocks() {
        // 2, 4, 5 and 7 characters are the only valid partial blocks.
        #expect(throws: BasesError.incompleteBlock) { try Base32.decode(Array("M".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base32.decode(Array("MZX".utf8)) }
        #expect(throws: BasesError.incompleteBlock) { try Base32.decode(Array("MZXW6Y".utf8)) }
    }

    /// A 2-character block carries 10 bits but only 8 of them are a byte; the spare bits
    /// must be zero. 'Y' (24) ends in `000`, 'Z' (25) does not.
    @Test func testRejectsStrayBits() throws {
        #expect(try Base32.decode("MY") == Array("f".utf8))
        #expect(throws: BasesError.strayBits) { try Base32.decode(Array("MZ".utf8)) }
    }

    /// The alphabets the multibase layer reads instead of duplicating the strings.
    @Test func testAlphabetsAreExposed() {
        #expect(Base32.Variant.standard.alphabet().characterString == "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        #expect(Base32.Variant.standard.alphabet(.lower).characterString == "abcdefghijklmnopqrstuvwxyz234567")
        #expect(Base32.Variant.hex.alphabet().characterString == "0123456789ABCDEFGHIJKLMNOPQRSTUV")
        #expect(Base32.Variant.hex.alphabet(.lower).characterString == "0123456789abcdefghijklmnopqrstuv")
        #expect(Base32.Variant.z.alphabet().characterString == "ybndrfg8ejkmcpqxot1uwisza345h769")
        #expect(Base32.Variant.z.alphabet(.upper).characterString == "YBNDRFG8EJKMCPQXOT1UWISZA345H769")
    }

    /// Compiles only if `decode` is declared `throws(BasesError)`, the `do throws(_)`
    /// annotation would be rejected otherwise, and `catch` binds `error` as a
    /// `BasesError` with no cast.
    @Test func testDecodeUsesTypedThrows() {
        let thrown: BasesError? = {
            do throws(BasesError) {
                _ = try Base32.decode(Array("MZXW6YT!".utf8))
                return nil
            } catch {
                return error
            }
        }()
        #expect(thrown == .nonAlphabetCharacter)
    }
}
