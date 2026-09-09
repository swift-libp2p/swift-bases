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

extension BaseX {

    @available(*, deprecated, renamed: "BasesError")
    public typealias BaseXError = BasesError

    @available(*, deprecated, message: "Use `BaseX.encodedString(Array(str.utf8), into:)`.")
    public static func encode(
        _ str: String,
        into base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let data = str.data(using: encoding) else { throw BasesError.invalidStringEncoding }
        return encodedString(data, into: base)
    }

    @available(*, deprecated, message: "Use `BaseX.encodedString(_:into:)`.")
    public static func encode(_ data: Data, into base: BaseX.Alphabets) -> String {
        encodedString(data, into: base)
    }

    @available(*, deprecated, message: "Use `String(decoding: try BaseX.decode(str, as:), as: UTF8.self)`.")
    public static func decode(
        _ str: String,
        as base: BaseX.Alphabets,
        using encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let res = String(data: Data(try decode(str.utf8, as: base)), encoding: encoding) else {
            throw BasesError.invalidStringEncoding
        }
        return res
    }

    @available(*, deprecated, message: "Use `BaseX.decode(_:as:)`, which returns `[UInt8]`.")
    public static func decode(_ str: String, as base: BaseX.Alphabets) throws -> Data {
        Data(try decode(str.utf8, as: base))
    }
}

extension Data {
    /// try Data(decoding: "429328951066508984658627669258025763026247056774804621697313" as: .base10Decimal) => Data
    @available(*, deprecated, message: "Use `BaseX.decode(_:as:)`, which returns `[UInt8]`.")
    public init(decoding encodedString: String, as base: BaseX.Alphabets) throws {
        self = Data(try BaseX.decode(encodedString.utf8, as: base))
    }
}

extension String {
    /// try String(decoding: "429328951066508984658627669258025763026247056774804621697313", as: .base10Decimal, using: .utf8) => "Decentralize everything!!"
    @available(*, deprecated, message: "Use `String(decoding: try BaseX.decode(str, as:), as: UTF8.self)`.")
    public init(
        decoding encodedString: String,
        as base: BaseX.Alphabets,
        using stringEncoding: String.Encoding = .utf8
    ) throws {
        let bytes = try BaseX.decode(encodedString.utf8, as: base)
        guard let str = String(bytes: bytes, encoding: stringEncoding) else {
            throw BasesError.invalidStringEncoding
        }
        self = str
    }
}
