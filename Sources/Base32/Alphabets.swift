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

//
//  Alphabet.swift
//  Bases
//
//  Copyright (c) 2015-2018 Matt Rubin and the Bases authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

internal typealias EncodedChar = UInt8

protocol Alphabet {
    static var paddingCharacter: EncodedChar { get }
    var paddingCharacter: EncodedChar { get }

    func character(encoding quintet: Quintet) -> Quintet
    func quintet(decoding char: EncodedChar) throws -> Quintet
}
public enum NullCharOpts {
    case drop
    case encode
}

public enum LetterCase {
    case upper
    case lower
}

public enum Base32Options {
    case pad(Bool)
    case nullChar(NullCharOpts)
    case letterCase(LetterCase)

    internal func apply(_ d: Data) -> Data {
        switch self {
        case .nullChar(.drop):
            return d.drop(while: { $0 == 0 })
        default:
            return d
        }
    }

    internal func apply(_ str: String) -> String {
        switch self {
        case .letterCase(.upper):
            return str.uppercased()
        case .letterCase(.lower):
            return str.lowercased()
        case .pad(false):
            return String(str.reversed().drop(while: { $0 == "=" }).reversed())
        default:
            return str
        }
    }
}

extension Data {
    func apply(_ opts: [Base32Options]) -> Data {
        opts.reduce(into: self) { (data, option) in
            data = option.apply(data)
        }
    }
}

extension String {
    func apply(_ opts: [Base32Options]) -> String {
        opts.reduce(into: self) { (str, option) in
            str = option.apply(str)
        }
    }
}

public enum Variant {
    case standard
    case hex
    case z

    internal var alphabet: Alphabet {
        switch self {
        case .standard: return Base32Alphabet()
        case .hex: return Base32HexAlphabet()
        case .z: return Base32ZAlphabet()
        }
    }
}

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

struct Base32Alphabet: Alphabet {
    static let paddingCharacter: EncodedChar = 61
    let paddingCharacter: EncodedChar = 61
    //    private let encodingTable: [EncodedChar] = [
    //        65, 66, 67, 68, 69, 70, 71, 72,
    //        73, 74, 75, 76, 77, 78, 79, 80,
    //        81, 82, 83, 84, 85, 86, 87, 88,
    //        89, 90, 50, 51, 52, 53, 54, 55,
    //    ]
    private let encodingTable: [EncodedChar] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
        "W", "X", "Y", "Z", "2", "3", "4", "5", "6", "7",
    ]
    .map { (c: UnicodeScalar) -> EncodedChar in EncodedChar(c.value) }

    func character(encoding quintet: Quintet) -> EncodedChar {
        encodingTable[Int(quintet)]
    }

    func quintet(decoding char: EncodedChar) throws -> Quintet {
        switch char {
        case 50...55:
            return char - 24
        case 65...90:
            return char - 65
        case 97...122:
            return char - 97
        default:
            throw Base32.Error.nonAlphabetCharacter
        }
    }
}

//              The The "Extended Hex" Base 32 Alphabet
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

struct Base32HexAlphabet: Alphabet {
    static let paddingCharacter: EncodedChar = 61
    let paddingCharacter: EncodedChar = 61
    private let encodingTable: [EncodedChar] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
        "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
    ]
    .map { (c: UnicodeScalar) -> EncodedChar in EncodedChar(c.value) }

    func character(encoding quintet: Quintet) -> EncodedChar {
        encodingTable[Int(quintet)]
    }

    func quintet(decoding char: EncodedChar) throws -> Quintet {
        switch char {
        case 48...57:
            return char - 48
        case 65...90:  //Capital Letters
            return char - 55
        case 97...122:  //Lowercased Letters
            return char - 87
        default:
            throw Base32.Error.nonAlphabetCharacter
        }
    }
}

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

struct Base32ZAlphabet: Alphabet {
    static let paddingCharacter: EncodedChar = 61
    let paddingCharacter: EncodedChar = 61
    private let encodingTable: [EncodedChar] = [
        "y", "b", "n", "d", "r", "f", "g", "8", "e", "j", "k", "m", "c", "p", "q", "x", "o", "t", "1", "u", "w", "i",
        "s", "z", "a", "3", "4", "5", "h", "7", "6", "9",
    ]
    .map { (c: UnicodeScalar) -> EncodedChar in EncodedChar(c.value) }

    func character(encoding quintet: Quintet) -> EncodedChar {
        encodingTable[Int(quintet)]
    }

    func quintet(decoding char: EncodedChar) throws -> Quintet {
        var c = char
        if char >= 65 && char <= 90 { c = char + 32 }  //Map Uppercase Letters to Lowercase range...
        if let match = encodingTable.firstIndex(of: c) {
            return UInt8(match)
        } else {
            throw Base32.Error.nonAlphabetCharacter
        }
    }
}
