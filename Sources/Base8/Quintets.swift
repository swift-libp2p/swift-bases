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
//  Quintets.swift
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

typealias Byte = UInt8
typealias Quintet = UInt8

func quintetsFromBytes(
    _ firstByte: Byte,
    _ secondByte: Byte,
    _ thirdByte: Byte
) -> (Quintet, Quintet, Quintet, Quintet, Quintet, Quintet, Quintet, Quintet) {
    (
        firstQuintet(firstByte: firstByte),
        secondQuintet(firstByte: firstByte),
        thirdQuintet(firstByte: firstByte, secondByte: secondByte),
        fourthQuintet(secondByte: secondByte),
        fifthQuintet(secondByte: secondByte),
        sixthQuintet(secondByte: secondByte, thirdByte: thirdByte),
        seventhQuintet(thirdByte: thirdByte),
        eighthQuintet(thirdByte: thirdByte)
    )
}

func quintetsFromBytes(_ firstByte: Byte, _ secondByte: Byte) -> (Quintet, Quintet, Quintet, Quintet, Quintet, Quintet)
{
    (
        firstQuintet(firstByte: firstByte),
        secondQuintet(firstByte: firstByte),
        thirdQuintet(firstByte: firstByte, secondByte: secondByte),
        fourthQuintet(secondByte: secondByte),
        fifthQuintet(secondByte: secondByte),
        sixthQuintet(secondByte: secondByte, thirdByte: 0)
    )
}

func quintetsFromBytes(_ firstByte: Byte) -> (Quintet, Quintet, Quintet) {
    (
        firstQuintet(firstByte: firstByte),
        secondQuintet(firstByte: firstByte),
        thirdQuintet(firstByte: firstByte, secondByte: 0)
    )
}

// MARK: - Private

private func firstQuintet(firstByte: Byte) -> Quintet {
    ((firstByte & 0b11100000) >> 5)
}

private func secondQuintet(firstByte: Byte) -> Quintet {
    ((firstByte & 0b00011100) >> 2)
}

private func thirdQuintet(firstByte: Byte, secondByte: Byte) -> Quintet {
    ((firstByte & 0b00000011) << 1)
        | ((secondByte & 0b10000000) >> 7)
}

private func fourthQuintet(secondByte: Byte) -> Quintet {
    ((secondByte & 0b01110000) >> 4)
}

private func fifthQuintet(secondByte: Byte) -> Quintet {
    ((secondByte & 0b00001110) >> 1)
}

private func sixthQuintet(secondByte: Byte, thirdByte: Byte) -> Quintet {
    ((secondByte & 0b00000001) << 2)
        | ((thirdByte & 0b11000000) >> 6)
}

private func seventhQuintet(thirdByte: Byte) -> Quintet {
    ((thirdByte & 0b00111000) >> 3)
}

private func eighthQuintet(thirdByte: Byte) -> Quintet {
    (thirdByte & 0b00000111)
}

//private func secondQuintet(firstByte: Byte, secondByte: Byte) -> Quintet {
//    return ((firstByte & 0b00000111) << 2)
//        | ((secondByte & 0b11000000) >> 6)
//}

//private func thirdQuintet(secondByte: Byte) -> Quintet {
//    return ((secondByte & 0b00111110) >> 1)
//}

//private func fourthQuintet(secondByte: Byte, thirdByte: Byte) -> Quintet {
//    return ((secondByte & 0b00000001) << 4)
//        | ((thirdByte & 0b11110000) >> 4)
//}

//private func fifthQuintet(thirdByte: Byte, fourthByte: Byte) -> Quintet {
//    return ((thirdByte & 0b00001111) << 1)
//        | ((fourthByte & 0b10000000) >> 7)
//}

//private func sixthQuintet(fourthByte: Byte) -> Quintet {
//    return ((fourthByte & 0b01111100) >> 2)
//}

//private func seventhQuintet(fourthByte: Byte, fifthByte: Byte) -> Quintet {
//    return ((fourthByte & 0b00000011) << 3)
//        | ((fifthByte & 0b11100000) >> 5)
//}
//
//private func eighthQuintet(fifthByte: Byte) -> Quintet {
//    return (fifthByte & 0b00011111)
//}
