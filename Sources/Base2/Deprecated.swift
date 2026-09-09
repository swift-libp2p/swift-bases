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
//  Deprecated.swift
//
//  Compatibility shims for the pre-0.4.0 API.
//

import Foundation

@available(*, deprecated, renamed: "BasesError")
public typealias Base2Error = BasesError

extension String {

    @available(*, deprecated, message: "Use `Base2.encodedString(Array(str.utf8), byteSpacing:)`.")
    public func binaryEncoded(using encoding: String.Encoding = .utf8, byteSpacing: Bool = false) -> String? {
        guard let data = self.data(using: encoding) else { return nil }
        return Base2.encodedString(data, byteSpacing: byteSpacing)
    }

    /// - Warning: Swallows every error, reporting malformed input as empty `Data`.
    ///   ``Base2/decode(_:)-(some StringProtocol)`` throws instead.
    @available(
        *,
        deprecated,
        message: "Use `Base2.decode(_:)`, which reports malformed input instead of swallowing it."
    )
    public var binaryDecoded: Data {
        guard let bytes = try? Base2.decode(self) else { return Data() }
        return Data(bytes)
    }

    @available(*, deprecated, message: "Use `String(decoding: try Base2.decode(str), as: UTF8.self)`.")
    public var binaryDecodedString: String? {
        guard let bytes = try? Base2.decode(self) else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }
}

extension Data {

    @available(*, deprecated, message: "Use `Base2.decode(_:)`.")
    public init(binaryString string: String) throws {
        self = Data(try Base2.decode(string))
    }
}

extension Array where Element == UInt8 {

    @available(*, deprecated, message: "Use `Base2.decode(_:)`.")
    public init(binaryString string: String) throws {
        self = try Base2.decode(string)
    }
}
