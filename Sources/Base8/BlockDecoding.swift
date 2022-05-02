
//
//  BlockDecoding.swift
//  Bases
//
//  Copyright (c) 2017-2018 Matt Rubin and the Bases authors
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

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, _ c4: EncodedChar, _ c5: EncodedChar, _ c6: EncodedChar, _ c7: EncodedChar, using a:Alphabet) throws -> (Byte, Byte, Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2),
             try a.quintet(decoding: c3),
             try a.quintet(decoding: c4),
             try a.quintet(decoding: c5),
             try a.quintet(decoding: c6),
             try a.quintet(decoding: c7))
    return bytesFromQuintets(q.0, q.1, q.2, q.3, q.4, q.5, q.6, q.7)
}

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, _ c4: EncodedChar, _ c5: EncodedChar, using a:Alphabet) throws -> (Byte, Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2),
             try a.quintet(decoding: c3),
             try a.quintet(decoding: c4),
             try a.quintet(decoding: c5))
    return try bytesFromQuintets(q.0, q.1, q.2, q.3, q.4, q.5)
}

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, using a:Alphabet) throws -> (Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2))
    return try bytesFromQuintets(q.0, q.1, q.2)
}

// MARK: -

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet, _ fifth: Quintet, _ sixth: Quintet, _ seventh: Quintet, _ eighth: Quintet) -> (Byte, Byte, Byte) {
    return (
        firstByte(firstQuintet: first, secondQuintet: second, thirdQuintet: third),
        secondByte(thirdQuintet: third, fourthQuintet: fourth, fifthQuintet: fifth, sixthQuintent: sixth),
        thirdByte(sixthQuintet: sixth, seventhQuintet: seventh, eighthQuintet: eighth)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet, _ fifth: Quintet, _ sixth: Quintet) throws -> (Byte, Byte) {
    guard sixth & 0b011 == 0 else {
        throw Base8.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second, thirdQuintet: third),
        secondByte(thirdQuintet: third, fourthQuintet: fourth, fifthQuintet: fifth, sixthQuintent: sixth)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet) throws -> (Byte) {
    guard third & 0b001 == 0 else {
        throw Base8.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second, thirdQuintet: third)
    )
}

// MARK: -

private func firstByte(firstQuintet: Quintet, secondQuintet: Quintet, thirdQuintet: Quintet) -> Byte {
    return ((firstQuintet & 0b111) << 5)
        | ((secondQuintet & 0b111) << 2)
        |  ((thirdQuintet & 0b110) >> 1)
}

private func secondByte(thirdQuintet: Quintet, fourthQuintet: Quintet, fifthQuintet: Quintet, sixthQuintent: Quintet) -> Byte {
    return ((thirdQuintet & 0b001) << 7)
        | ((fourthQuintet & 0b111) << 4)
        |  ((fifthQuintet & 0b111) << 1)
        | ((sixthQuintent & 0b100) >> 2)
}

private func thirdByte(sixthQuintet: Quintet, seventhQuintet: Quintet, eighthQuintet: Quintet) -> Byte {
    return  ((sixthQuintet & 0b011) << 6)
        | ((seventhQuintet & 0b111) << 3)
        |  ((eighthQuintet & 0b111))
}
