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

internal typealias EncodedChar = UInt8

protocol Alphabet {
    static var paddingCharacter: EncodedChar { get }

    func character(encoding quintet: Quintet) -> Quintet
    func quintet(decoding char: EncodedChar) throws -> Quintet
}

struct Base8Alphabet: Alphabet {
    static let paddingCharacter: EncodedChar = 61
    private let encodingTable: [EncodedChar] = ["0", "1", "2", "3", "4", "5", "6", "7"]
        .map { (c: UnicodeScalar) -> EncodedChar in EncodedChar(c.value) }

    func character(encoding quintet: Quintet) -> EncodedChar {
        encodingTable[Int(quintet)]
    }

    func quintet(decoding char: EncodedChar) throws -> Quintet {
        guard case 48...56 = char else {
            print("NonNumericCharacter: \(char)")
            throw Base8.Error.nonNumericCharacter
        }
        //guard char >= 48 && char <= 57 else { throw Base8.Error.nonNumericCharacter }
        return char - 48
    }
}
