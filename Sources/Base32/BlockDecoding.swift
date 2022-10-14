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

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, _ c4: EncodedChar, _ c5: EncodedChar, _ c6: EncodedChar, _ c7: EncodedChar, using a:Alphabet) throws -> (Byte, Byte, Byte, Byte, Byte) {
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

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, _ c4: EncodedChar, _ c5: EncodedChar, _ c6: EncodedChar, using a:Alphabet) throws -> (Byte, Byte, Byte, Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2),
             try a.quintet(decoding: c3),
             try a.quintet(decoding: c4),
             try a.quintet(decoding: c5),
             try a.quintet(decoding: c6))
    return try bytesFromQuintets(q.0, q.1, q.2, q.3, q.4, q.5, q.6)
}

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, _ c4: EncodedChar, using a:Alphabet) throws -> (Byte, Byte, Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2),
             try a.quintet(decoding: c3),
             try a.quintet(decoding: c4))
    return try bytesFromQuintets(q.0, q.1, q.2, q.3, q.4)
}

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, _ c2: EncodedChar, _ c3: EncodedChar, using a:Alphabet) throws -> (Byte, Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1),
             try a.quintet(decoding: c2),
             try a.quintet(decoding: c3))
    return try bytesFromQuintets(q.0, q.1, q.2, q.3)
}

internal func decodeBlock(_ c0: EncodedChar, _ c1: EncodedChar, using a:Alphabet) throws -> (Byte) {
    let q = (try a.quintet(decoding: c0),
             try a.quintet(decoding: c1))
    return try bytesFromQuintets(q.0, q.1)
}

// MARK: -

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet, _ fifth: Quintet, _ sixth: Quintet, _ seventh: Quintet, _ eighth: Quintet) -> (Byte, Byte, Byte, Byte, Byte) {
    return (
        firstByte(firstQuintet: first, secondQuintet: second),
        secondByte(secondQuintet: second, thirdQuintet: third, fourthQuintet: fourth),
        thirdByte(fourthQuintet: fourth, fifthQuintet: fifth),
        fourthByte(fifthQuintet: fifth, sixthQuintet: sixth, seventhQuintet: seventh),
        fifthByte(seventhQuintet: seventh, eighthQuintet: eighth)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet, _ fifth: Quintet, _ sixth: Quintet, _ seventh: Quintet) throws -> (Byte, Byte, Byte, Byte) {
    guard seventh & 0b00111 == 0 else {
        throw Base32.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second),
        secondByte(secondQuintet: second, thirdQuintet: third, fourthQuintet: fourth),
        thirdByte(fourthQuintet: fourth, fifthQuintet: fifth),
        fourthByte(fifthQuintet: fifth, sixthQuintet: sixth, seventhQuintet: seventh)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet, _ fifth: Quintet) throws -> (Byte, Byte, Byte) {
    guard fifth & 0b00001 == 0 else {
        throw Base32.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second),
        secondByte(secondQuintet: second, thirdQuintet: third, fourthQuintet: fourth),
        thirdByte(fourthQuintet: fourth, fifthQuintet: fifth)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet, _ third: Quintet, _ fourth: Quintet) throws -> (Byte, Byte) {
    guard fourth & 0b01111 == 0 else {
        throw Base32.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second),
        secondByte(secondQuintet: second, thirdQuintet: third, fourthQuintet: fourth)
    )
}

private func bytesFromQuintets(_ first: Quintet, _ second: Quintet) throws -> (Byte) {
    guard second & 0b00011 == 0 else {
        throw Base32.Error.strayBits
    }
    return (
        firstByte(firstQuintet: first, secondQuintet: second)
    )
}

// MARK: -

//private func firstByte(firstQuintet: Quintet, secondQuintet: Quintet) -> Byte {
//    return ((firstQuintet & 0b11111) << 3)
//        | ((secondQuintet & 0b11100) >> 2)
//}
//
//private func secondByte(secondQuintet: Quintet, thirdQuintet: Quintet, fourthQuintet: Quintet) -> Byte {
//    return ((secondQuintet & 0b00011) << 6)
//        | ((thirdQuintet & 0b11111) << 1)
//        | ((fourthQuintet & 0b10000) >> 4)
//}
//
//private func thirdByte(fourthQuintet: Quintet, fifthQuintet: Quintet) -> Byte {
//    return ((fourthQuintet & 0b01111) << 4)
//        | ((fifthQuintet & 0b11110) >> 1)
//}
//
//private func fourthByte(fifthQuintet: Quintet, sixthQuintet: Quintet, seventhQuintet: Quintet) -> Byte {
//    return ((fifthQuintet & 0b00001) << 7)
//        | ((sixthQuintet & 0b11111) << 2)
//        | ((seventhQuintet & 0b11000) >> 3)
//}
//
//private func fifthByte(seventhQuintet: Quintet, eighthQuintet: Quintet) -> Byte {
//    return ((seventhQuintet & 0b00111) << 5)
//        | (eighthQuintet & 0b11111)
//}

private func firstByte(firstQuintet: Quintet, secondQuintet: Quintet) -> Byte {
    return leftShift(  firstQuintet, mask: 0b11111, amount: 3)
         | rightShift(secondQuintet, mask: 0b11100, amount: 2)
}

private func secondByte(secondQuintet: Quintet, thirdQuintet: Quintet, fourthQuintet: Quintet) -> Byte {
    return leftShift( secondQuintet, mask: 0b00011, amount: 6)
         | leftShift(  thirdQuintet, mask: 0b11111, amount: 1)
         | rightShift(fourthQuintet, mask: 0b10000, amount: 4)
}

private func thirdByte(fourthQuintet: Quintet, fifthQuintet: Quintet) -> Byte {
    return leftShift(fourthQuintet, mask:0b01111, amount: 4)
         | rightShift(fifthQuintet, mask:0b11110, amount: 1)
}

private func fourthByte(fifthQuintet: Quintet, sixthQuintet: Quintet, seventhQuintet: Quintet) -> Byte {
    return leftShift(   fifthQuintet, mask: 0b00001, amount: 7)
         | leftShift(   sixthQuintet, mask: 0b11111, amount: 2)
         | rightShift(seventhQuintet, mask: 0b11000, amount: 3)
}

private func fifthByte(seventhQuintet: Quintet, eighthQuintet: Quintet) -> Byte {
    return leftShift(seventhQuintet, mask: 0b00111, amount: 5)
         | leftShift( eighthQuintet, mask: 0b11111, amount: 0)
}


private func leftShift(_ quintet:Quintet, mask:Byte, amount:Int) -> Byte {
    return (quintet & mask) << amount
}

private func rightShift(_ quintet:Quintet, mask:Byte, amount:Int) -> Byte {
    return (quintet & mask) >> amount
}
