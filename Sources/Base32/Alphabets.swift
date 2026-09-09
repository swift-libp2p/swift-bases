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

import BasesCore

// The cached base32 alphabets.
//
// Each 5-bit group is used as an index into an array of 32 printable
// characters.  The character referenced by the index is placed in the
// output string.  These characters, identified in Table 3, below, are
// selected from US-ASCII digits and uppercase letters.
//
//                   Table 3: The Base 32 Alphabet
//
//   Value Encoding  Value Encoding  Value Encoding  Value Encoding
//       0 A             9 J            18 S            27 3
//       1 B            10 K            19 T            28 4
//       2 C            11 L            20 U            29 5
//       3 D            12 M            21 V            30 6
//       4 E            13 N            22 W            31 7
//       5 F            14 O            23 X
//       6 G            15 P            24 Y         (pad) =
//       7 H            16 Q            25 Z
//       8 I            17 R            26 2
//
//              The "Extended Hex" Base 32 Alphabet
//
//   Value Encoding  Value Encoding  Value Encoding  Value Encoding
//       0 0             9 9            18 I            27 R
//       1 1            10 A            19 J            28 S
//       2 2            11 B            20 K            29 T
//       3 3            12 C            21 L            30 U
//       4 4            13 D            22 M            31 V
//       5 5            14 E            23 N
//       6 6            15 F            24 O         (pad) =
//       7 7            16 G            25 P
//       8 8            17 H            26 Q
//
//                    The Z Base 32 Alphabet
//
//   Value Encoding  Value Encoding  Value Encoding  Value Encoding
//       0 y             9 j            18 1            27 5
//       1 b            10 k            19 u            28 h
//       2 n            11 m            20 w            29 7
//       3 d            12 c            21 i            30 6
//       4 r            13 p            22 s            31 9
//       5 f            14 q            23 z
//       6 g            15 x            24 a         (pad) =
//       7 8            16 o            25 3
//       8 e            17 t            26 4

internal typealias EncodedChar = UInt8

/// The character that pads a partial final block.
internal let paddingCharacter: EncodedChar = Alphabet.paddingCharacter

extension Base32 {

    /// Which base32 alphabet to use.
    public enum Variant: Sendable {
        /// RFC 4648 base32: `A`-`Z` then `2`-`7` (multibase `b` / `B` / `c` / `C`).
        case standard

        /// RFC 4648 base32 "extended hex": `0`-`9` then `A`-`V` (multibase `v` / `V` / `t` / `T`).
        case hex

        /// z-base-32, a human-oriented permutation of the alphabet (multibase `h`).
        case z

        /// The case this variant's alphabet is defined in.
        public var naturalCase: LetterCase {
            self == .z ? .lower : .upper
        }

        /// This variant's alphabet, in the requested case.
        ///
        /// - Parameter letterCase: The case to render letters in. Defaults to ``naturalCase``.
        /// - Returns: A cached alphabet
        public func alphabet(_ letterCase: LetterCase? = nil) -> Alphabet {
            switch (self, letterCase ?? naturalCase) {
            case (.standard, .upper): Alphabets.standardUpper
            case (.standard, .lower): Alphabets.standardLower
            case (.hex, .upper): Alphabets.hexUpper
            case (.hex, .lower): Alphabets.hexLower
            case (.z, .upper): Alphabets.zUpper
            case (.z, .lower): Alphabets.zLower
            }
        }

        /// The alphabet to decode with.
        ///
        /// All three variants decode case-insensitively, so the natural-case table serves both
        /// cases and there is no need to case-convert the input first.
        internal var decodingAlphabet: Alphabet {
            alphabet(naturalCase)
        }
    }
}

internal enum Alphabets {
    static let standardUpper = Alphabet("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", caseInsensitive: true)
    static let standardLower = standardUpper.lowercased()

    static let hexUpper = Alphabet("0123456789ABCDEFGHIJKLMNOPQRSTUV", caseInsensitive: true)
    static let hexLower = hexUpper.lowercased()

    static let zLower = Alphabet("ybndrfg8ejkmcpqxot1uwisza345h769", caseInsensitive: true)
    static let zUpper = zLower.uppercased()
}
