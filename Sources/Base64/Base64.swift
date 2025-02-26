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

extension String {
    /// Ensures a base64 encoded string is a multiple of 4 and has the correct padding if necessary...
    public var base64CompliantString: String {
        if self.count % 4 == 0 {
            return self
        } else {
            return self.padding(toLength: self.count + (4 - (self.count % 4)), withPad: "=", startingAt: 0)
        }
    }

    fileprivate var dropPadding: String {
        String(self.reversed().drop(while: { $0 == "=" }).reversed())
    }
}

extension Data {

    public init?(base64URLEncoded string: String) {
        let base64URL =
            string
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+").base64CompliantString
        self.init(base64Encoded: base64URL)
    }

    public init?(base64URLEncoded data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        self.init(base64URLEncoded: string)
    }

    public func base64URLEncoded(padded: Bool = true) -> String {
        let b64url = self.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return padded ? b64url : b64url.dropPadding
    }

    public func base64Encoded(padded: Bool = true) -> String {
        let b64 = self.base64EncodedString()
        return padded ? b64 : b64.dropPadding
    }

    public func base64URLPadEncodedData() -> Data? {
        self.base64URLEncoded(padded: true).data(using: .utf8)
    }

}
