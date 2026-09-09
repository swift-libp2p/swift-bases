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

extension Base64 {

    @available(*, deprecated, renamed: "BasesError")
    public typealias Error = BasesError

    /// Encodes bytes as a base64 string in the given variant, optionally padded.
    @available(*, deprecated, message: "Use `Base64.encodedString(_:variant:pad:)`.")
    public static func encode(_ data: Data, variant: Variant = .standard, pad: Bool = true) -> String {
        encodedString(data, variant: variant, pad: PadOption(pad))
    }

    /// Encodes a string's UTF-8 bytes as a base64 string in the given variant.
    @available(*, deprecated, message: "Use `Base64.encodedString(Array(str.utf8), variant:pad:)`.")
    public static func encode(_ str: String, variant: Variant = .standard, pad: Bool = true) -> String {
        encodedString(str.utf8, variant: variant, pad: PadOption(pad))
    }

    /// Decodes a base64 string (padded or unpadded) in the given variant into bytes.
    @available(*, deprecated, message: "Use `Base64.decode(_:variant:)`, which returns `[UInt8]`.")
    public static func decode(_ string: String, variant: Variant = .standard) throws -> Data {
        Data(try decode(string.utf8, variant: variant))
    }

    /// Decodes a base64 string and interprets the resulting bytes as a `String`.
    @available(*, deprecated, message: "Use `String(decoding: try Base64.decode(str), as: UTF8.self)`.")
    public static func decodeToString(
        _ string: String,
        variant: Variant = .standard,
        using strEncoding: String.Encoding = .utf8
    ) throws -> String {
        guard let str = String(data: Data(try decode(string.utf8, variant: variant)), encoding: strEncoding) else {
            throw BasesError.invalidStringEncoding
        }
        return str
    }
}

extension String {
    /// Ensures a base64 encoded string is a multiple of 4 and has the correct padding if necessary...
    @available(
        *,
        deprecated,
        message: "No longer needed — `Base64.decode(_:variant:)` accepts unpadded input directly."
    )
    public var base64CompliantString: String {
        if self.count % 4 == 0 {
            return self
        } else {
            return self.padding(toLength: self.count + (4 - (self.count % 4)), withPad: "=", startingAt: 0)
        }
    }
}

extension Data {

    /// Decodes a URL-safe base64 string (padded or unpadded) into bytes.
    @available(*, deprecated, message: "Use `Base64.decode(_:variant: .url)`.")
    public init(base64URLEncoded string: String) throws {
        self = Data(try Base64.decode(string.utf8, variant: .url))
    }

    /// Decodes URL-safe base64 held as UTF-8 `Data` into the decoded bytes.
    @available(*, deprecated, message: "Use `Base64.decode(_:variant: .url)`, which takes any byte collection.")
    public init(base64URLEncoded data: Data) throws {
        self = Data(try Base64.decode(data, variant: .url))
    }

    @available(*, deprecated, message: "Use `Base64.encodedString(_:variant: .url, pad:)`.")
    public func base64URLEncoded(padded: Bool = true) -> String {
        Base64.encodedString(self, variant: .url, pad: PadOption(padded))
    }

    @available(*, deprecated, message: "Use `Base64.encodedString(_:pad:)`.")
    public func base64Encoded(padded: Bool = true) -> String {
        Base64.encodedString(self, variant: .standard, pad: PadOption(padded))
    }

    @available(*, deprecated, message: "Use `Data(Base64.encode(_:variant: .url))`.")
    public func base64URLPadEncodedData() -> Data? {
        Data(Base64.encode(self, variant: .url, pad: .padded))
    }
}
