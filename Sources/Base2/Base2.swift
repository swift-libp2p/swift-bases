//
//  Base2.swift
//  
//
//  Created by Brandon Toms on 5/1/22.
//

import Foundation

public enum Base2Error:Error {
    case invalidBinaryCharacter
}

public extension String {
    func binaryEncoded(using encoding:String.Encoding = .utf8, byteSpacing:Bool = false) -> String? {
        guard let d = self.data(using: encoding) else { return nil }
        return d.binaryEncoded(byteSpacing: byteSpacing)
    }
    
    var binaryDecoded:Data {
        let s = self.replacingOccurrences(of: " ", with: "")
        guard s.filter({ $0 == "0" || $0 == "1" }).count == s.count else { return Data() }
        var bytes:[UInt8] = []
        var zeros = 0
        for byte in s.chunked(into: 8) {
            if let u = UInt8(byte, radix: 2) {
                //print("Binary Byte: \(byte) => \(u)")
                if u == 0 { zeros += 1 }
                bytes.append(u)
            }
        }
        return Data(bytes)
    }
    
    var binaryDecodedString:String? {
        return try? Data(binaryString: self).map { String(UnicodeScalar($0)) }.joined()
        //return self.binaryDecoded.map { String(UnicodeScalar($0)) }.joined()
    }
    
    internal static func padByte(_ byte:UInt8) -> String {
        String(String(String(byte, radix: 2).reversed()).padding(toLength: 8, withPad: "0", startingAt: 0).reversed())
    }
}

public extension Data {
    
    /// Data[1].binaryEncoded() -> "00000001"
    func binaryEncoded(byteSpacing:Bool = false) -> String {
        Array<UInt8>(self).binaryEncoded(byteSpacing: byteSpacing)
    }
    
    /// Data(binaryString: "00000001") => [1]
    init(binaryString str:String) throws {
        try self.init([UInt8](binaryString: str))
    }
}

public extension Array where Element == UInt8 {
    
    /// Array<UInt8>[1].binaryEncoded() -> "00000001"
    func binaryEncoded(byteSpacing:Bool = false) -> String {
        self.reduce("") { (accumulator, byte) -> String in
            return accumulator + ((accumulator.isEmpty || !byteSpacing) ? "" : " ") + String.padByte(byte)
        }
    }
    
    /// Array<UInt8>(binaryString: "00000001") => [1]
    init(binaryString str:String) throws {
        let s = str.replacingOccurrences(of: " ", with: "")
        guard s.filter({ $0 == "0" || $0 == "1" }).count == s.count else { throw Base2Error.invalidBinaryCharacter }
        self = []
        var zeros = 0
        for byte in s.chunked(into: 8) {
            if let u = UInt8(byte, radix: 2) {
                //print("Binary Byte: \(byte) => \(u)")
                if u == 0 { zeros += 1 }
                self.append(u)
            }
        }
    }
}

fileprivate extension Collection {
    func chunked(into size: Int) -> [SubSequence] {
        var chunks: [SubSequence] = []
        chunks.reserveCapacity((underestimatedCount + size - 1) / size)
        
        var residual = self[...], splitIndex = startIndex
        while formIndex(&splitIndex, offsetBy: size, limitedBy: endIndex) {
            chunks.append(residual.prefix(upTo: splitIndex))
            residual = residual.suffix(from: splitIndex)
        }
        
        return residual.isEmpty ? chunks : chunks + CollectionOfOne(residual)
    }
}
