//
//  Base64.swift
//  
//
//  Created by Brandon Toms on 5/1/22.
//

import Foundation

public extension String {
    /// Ensures a base64 encoded string is a multiple of 4 and has the correct padding if necessary...
    var base64CompliantString:String {
        if self.count % 4 == 0 { return self }
        else {
            return self.padding(toLength: self.count + (4 - (self.count % 4)), withPad: "=", startingAt: 0)
        }
    }
    
    fileprivate var dropPadding:String {
        return String(self.reversed().drop(while: {$0 == "="}).reversed())
    }
}

public extension Data {

    init?(base64URLEncoded string: String) {
        let base64URL = string
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+").base64CompliantString
        self.init(base64Encoded: base64URL)
    }

    init?(base64URLEncoded data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        self.init(base64URLEncoded: string)
    }

    func base64URLEncoded(padded:Bool = true) -> String {
        let b64url = self.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return padded ? b64url : b64url.dropPadding
    }
    
    func base64Encoded(padded:Bool = true) -> String {
        let b64 = self.base64EncodedString()
        return padded ? b64 : b64.dropPadding
    }
    
    func base64URLPadEncodedData() -> Data? {
        return self.base64URLEncoded(padded: true).data(using: .utf8)
    }

}
