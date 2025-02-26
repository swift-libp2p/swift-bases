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

private func buildAlphabetBase(_ alphabet: String) -> AlphabetBase {
    let characters = Array(alphabet)
    let indexed: [Character] = characters.map { $0 }
    var tmpMap = [Character: UInt]()
    var i: UInt = 0
    for c in characters {
        tmpMap[c] = i
        i += 1
    }

    let finalMap = tmpMap
    return AlphabetBase(map: finalMap, indexed: indexed, base: UInt(characters.count), leader: characters.first!)
}

private struct AlphabetBase {
    let map: [Character: UInt]
    let indexed: [Character]
    let base: UInt
    let leader: Character
}

public enum BaseX {
    public enum BaseXError: Error {
        case invalidStringEncoding
        case invalidCharacter
    }

    public enum Alphabets: Equatable {
        case base10Decimal
        case base16Hex
        case base16HexUpper
        case base36
        case base36Upper
        case base58BTC
        case base58Flickr
        case custom(String)

        fileprivate var alphabet: AlphabetBase {
            switch self {
            case .base10Decimal:
                return buildAlphabetBase("0123456789")
            case .base16Hex:
                return buildAlphabetBase("0123456789abcdef")
            case .base16HexUpper:
                return buildAlphabetBase("0123456789ABCDEF")
            case .base36:
                return buildAlphabetBase("0123456789abcdefghijklmnopqrstuvwxyz")
            case .base36Upper:
                return buildAlphabetBase("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            case .base58BTC:
                return buildAlphabetBase("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
            case .base58Flickr:
                return buildAlphabetBase("123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ")
            case .custom(let alphabet):
                return buildAlphabetBase(alphabet)
            }
        }

        fileprivate var charsPerBit: Int {
            switch self {
            case .base16Hex: return 2
            case .base16HexUpper: return 2
            default: return 1
            }
        }
    }

    static func encodeALT(
        _ str: String,
        into base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let data = str.data(using: encoding) else { throw BaseX.BaseXError.invalidStringEncoding }
        return BaseX.encodeALT(data, into: base)
    }

    static func encodeALT(_ data: Data, into base: BaseX.Alphabets) -> String {
        let alpha = base.alphabet
        if data.count == 0 {
            return ""
        }
        let bytes = [UInt8](data)

        var digits: [UInt] = [0]
        for byte in bytes {
            var carry = UInt(byte)
            for j in 0..<digits.count {
                carry += digits[j] << 8
                digits[j] = carry % alpha.base
                carry = (carry / alpha.base) | 0
            }
            while carry > 0 {
                digits.append(carry % alpha.base)
                carry = (carry / alpha.base) | 0
            }
        }

        /// If our data is a bunch of zeros, then remove the initial zero from our digits array
        if digits == [0] { digits = [] }

        var output: String = ""
        // deal with leading zeros
        for k in 0..<data.count {
            if bytes[k] == UInt8(0) {
                output.append(contentsOf: Array(repeating: alpha.leader, count: base.charsPerBit))
            } else {
                break
            }
        }

        //Ensure we don't drop base16 leading zero
        switch base {
        case .base16Hex, .base16HexUpper:
            if digits.count % 2 == 1 {
                output.append(alpha.leader)
            }
        default:
            break
        }

        // convert digits to a string
        for d in digits.reversed() {
            output.append(alpha.indexed[Int(d)])
        }

        let final = output
        return final
    }

    public static func encode(
        _ str: String,
        into base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let data = str.data(using: encoding) else { throw BaseX.BaseXError.invalidStringEncoding }
        return BaseX.encode(data, into: base)
    }

    public static func encode(_ data: Data, into base: BaseX.Alphabets) -> String {
        guard base == .base16Hex || base == .base16HexUpper else { return BaseX.encodeALT(data, into: base) }
        if base == .base16Hex {
            return [UInt8](data).toHexString()
        } else {
            return [UInt8](data).toHexString().uppercased()
        }
    }

    static func decodeALT(
        _ str: String,
        as base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let res = String(data: try BaseX.decodeALT(str, as: base), encoding: encoding) else {
            throw BaseX.BaseXError.invalidStringEncoding
        }
        return res
    }

    static func decodeALT(_ str: String, as base: BaseX.Alphabets) throws -> Data {
        if str.isEmpty { return Data() }

        let alpha = base.alphabet

        var bytes: [UInt8] = [0]
        let characters = Array(str)
        for c in characters {
            if alpha.map[c] == nil { throw BaseX.BaseXError.invalidCharacter }
            var carry = alpha.map[c]!

            for j in 0..<bytes.count {
                carry += UInt(bytes[j]) * alpha.base
                bytes[j] = UInt8(carry & 0xff)
                carry >>= 8
            }

            while carry > 0 {
                bytes.append(UInt8(carry & 0xff))
                carry >>= 8
            }
        }

        // deal with leading zeros
        let leadingZero = Array(repeating: alpha.leader, count: base.charsPerBit)[0...]
        let charArray = Array(str)
        for k in stride(from: 0, to: characters.count, by: base.charsPerBit) {
            guard str.count > k + base.charsPerBit else { break }  //prevent index out of bounds error
            if charArray[k..<(k + base.charsPerBit)] == leadingZero {
                bytes.append(0)
            } else {
                break
            }
        }

        return Data(bytes.reversed())
    }

    public static func decode(
        _ str: String,
        as base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let res = String(data: try BaseX.decode(str, as: base), encoding: encoding) else {
            throw BaseX.BaseXError.invalidStringEncoding
        }
        return res
    }

    public static func decode(_ str: String, as base: BaseX.Alphabets) throws -> Data {
        guard base == .base16Hex || base == .base16HexUpper else { return try BaseX.decodeALT(str, as: base) }
        return Data([UInt8](hex: str))
    }

}

extension Data {
    /// try Data(decoding: "429328951066508984658627669258025763026247056774804621697313" as: .base10Decimal) => Data
    public init(decoding encodedString: String, as base: BaseX.Alphabets) throws {
        self = try BaseX.decode(encodedString, as: base)
    }

    //    var asHexString:String {
    //        self.map { String($0, radix: 16) }.joined()
    //    }

    //    func asString(base:BaseX.Alphabets) -> String {
    //        return BaseX.encode(self, into: base)
    //    }
}

extension String {
    /// try String(decoding: "429328951066508984658627669258025763026247056774804621697313", as: .base10Decimal, using: .utf8) => "Decentralize everything!!"
    public init(
        decoding encodedString: String,
        as base: BaseX.Alphabets,
        using stringEncoding: String.Encoding = .utf8
    ) throws {
        let d = try Data(decoding: encodedString, as: base)
        guard let str = String(data: d, encoding: stringEncoding) else { throw BaseX.BaseXError.invalidStringEncoding }
        self = str
    }
}

//CryptoSwift's hex decoding implementation. Way faster than our current implementation.
// It's nice to use the same library / implementation for multiple bases but we should try and optimize for base16 (hex) cause it's so often used...

//
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

extension Array {
    init(reserveCapacity: Int) {
        self = [Element]()
        self.reserveCapacity(reserveCapacity)
    }

    var slice: ArraySlice<Element> {
        self[self.startIndex..<self.endIndex]
    }
}

extension Array where Element == UInt8 {
    init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }

    func toHexString() -> String {
        `lazy`.reduce(into: "") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            $0 += s
        }
    }
}

/// Another Implementation (not sure if it's faster, same or slower, just another implementation
//
//struct Base58 {
//    static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
//
//    // Encode
//    static func base58FromBytes(_ bytes: [UInt8]) -> String {
//        var bytes = bytes
//        var zerosCount = 0
//        var length = 0
//
//        for b in bytes {
//            if b != 0 { break }
//            zerosCount += 1
//        }
//
//        bytes.removeFirst(zerosCount)
//
//        let size = bytes.count * 138 / 100 + 1
//
//        var base58: [UInt8] = Array(repeating: 0, count: size)
//        for b in bytes {
//            var carry = Int(b)
//            var i = 0
//
//            for j in 0...base58.count-1 where carry != 0 || i < length {
//                carry += 256 * Int(base58[base58.count - j - 1])
//                base58[base58.count - j - 1] = UInt8(carry % 58)
//                carry /= 58
//                i += 1
//            }
//
//            assert(carry == 0)
//
//            length = i
//        }
//
//        // skip leading zeros
//        var zerosToRemove = 0
//        var str = ""
//        for b in base58 {
//            if b != 0 { break }
//            zerosToRemove += 1
//        }
//        base58.removeFirst(zerosToRemove)
//
//        while 0 < zerosCount {
//            str = "\(str)1"
//            zerosCount -= 1
//        }
//
//        for b in base58 {
//            str = "\(str)\(base58Alphabet[String.Index(encodedOffset: Int(b))])"
//        }
//
//        return str
//    }
//
//    // Decode
//    static func bytesFromBase58(_ base58: String) -> [UInt8] {
//        // remove leading and trailing whitespaces
//        let string = base58.trimmingCharacters(in: CharacterSet.whitespaces)
//
//        guard !string.isEmpty else { return [] }
//
//        var zerosCount = 0
//        var length = 0
//        for c in string {
//            if c != "1" { break }
//            zerosCount += 1
//        }
//
//        let size = string.lengthOfBytes(using: String.Encoding.utf8) * 733 / 1000 + 1 - zerosCount
//        var base58: [UInt8] = Array(repeating: 0, count: size)
//        for c in string where c != " " {
//            // search for base58 character
//            guard let base58Index = base58Alphabet.firstIndex(of: c) else { return [] }
//
//            var carry = base58Index.utf16Offset(in: base58Alphabet)
//            var i = 0
//            for j in 0...base58.count where carry != 0 || i < length {
//                carry += 58 * Int(base58[base58.count - j - 1])
//                base58[base58.count - j - 1] = UInt8(carry % 256)
//                carry /= 256
//                i += 1
//            }
//
//            assert(carry == 0)
//            length = i
//        }
//
//        // skip leading zeros
//        var zerosToRemove = 0
//
//        for b in base58 {
//            if b != 0 { break }
//            zerosToRemove += 1
//        }
//        base58.removeFirst(zerosToRemove)
//
//        var result: [UInt8] = Array(repeating: 0, count: zerosCount)
//        for b in base58 {
//            result.append(b)
//        }
//        return result
//    }
//}
