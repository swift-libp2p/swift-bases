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

//
//  BlockEncoding.swift
//  Bases
//
//  Copyright (c) 2016-2019 Matt Rubin and the Bases authors
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

import BasesCore

internal typealias EncodedBlock = (
    EncodedChar, EncodedChar, EncodedChar, EncodedChar, EncodedChar,
    EncodedChar, EncodedChar, EncodedChar
)

/// Encodes `count` bytes of `bytes`, starting at `offset`, into a block of eight characters.
internal func encodeBlock(
    _ bytes: UnsafeBufferPointer<Byte>,
    at offset: Int,
    count: Int,
    using table: UnsafeBufferPointer<EncodedChar>
) -> EncodedBlock {
    switch count {
    case 1:
        return encodeBlock(bytes[offset], using: table)
    case 2:
        return encodeBlock(bytes[offset], bytes[offset + 1], using: table)
    case 3:
        return encodeBlock(bytes[offset], bytes[offset + 1], bytes[offset + 2], using: table)
    default:
        fatalError("Cannot encode \(count) bytes. Max block size is 3.")
    }
}

/// Writes an encoded block into `characters` starting at `offset`.
internal func write(_ block: EncodedBlock, into characters: UnsafeMutableBufferPointer<EncodedChar>, at offset: Int) {
    characters[offset + 0] = block.0
    characters[offset + 1] = block.1
    characters[offset + 2] = block.2
    characters[offset + 3] = block.3
    characters[offset + 4] = block.4
    characters[offset + 5] = block.5
    characters[offset + 6] = block.6
    characters[offset + 7] = block.7
}

private func encodeBlock(
    _ b0: Byte,
    _ b1: Byte,
    _ b2: Byte,
    using table: UnsafeBufferPointer<EncodedChar>
) -> EncodedBlock {
    let q = quintetsFromBytes(b0, b1, b2)
    let c0 = table[Int(q.0)]
    let c1 = table[Int(q.1)]
    let c2 = table[Int(q.2)]
    let c3 = table[Int(q.3)]
    let c4 = table[Int(q.4)]
    let c5 = table[Int(q.5)]
    let c6 = table[Int(q.6)]
    let c7 = table[Int(q.7)]
    return (c0, c1, c2, c3, c4, c5, c6, c7)
}

private func encodeBlock(_ b0: Byte, _ b1: Byte, using table: UnsafeBufferPointer<EncodedChar>) -> EncodedBlock {
    let q = quintetsFromBytes(b0, b1)
    let c0 = table[Int(q.0)]
    let c1 = table[Int(q.1)]
    let c2 = table[Int(q.2)]
    let c3 = table[Int(q.3)]
    let c4 = table[Int(q.4)]
    let c5 = table[Int(q.5)]
    let c6 = paddingCharacter
    let c7 = paddingCharacter
    return (c0, c1, c2, c3, c4, c5, c6, c7)
}

private func encodeBlock(_ b0: Byte, using table: UnsafeBufferPointer<EncodedChar>) -> EncodedBlock {
    let q = quintetsFromBytes(b0)
    let c0 = table[Int(q.0)]
    let c1 = table[Int(q.1)]
    let c2 = table[Int(q.2)]
    let c3 = paddingCharacter
    let c4 = paddingCharacter
    let c5 = paddingCharacter
    let c6 = paddingCharacter
    let c7 = paddingCharacter
    return (c0, c1, c2, c3, c4, c5, c6, c7)
}
