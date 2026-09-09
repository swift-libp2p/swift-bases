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

extension Base8 {

    @available(*, deprecated, renamed: "BasesError")
    public typealias Error = BasesError

    @available(*, deprecated, renamed: "NullCharOption")
    public typealias NullCharOpts = NullCharOption

    /// The pre-0.4.0 options bag.
    ///
    /// The byte-native entry points take the options as parameters instead:
    /// `Base8.encode(bytes, pad: .unpadded)`, and leading null bytes are dropped by
    /// slicing the input, `Base8.encode(bytes.drop(while: { $0 == 0 }))`.
    public enum Base8Options: Sendable {
        case pad(Bool)
        case nullChar(NullCharOption)
    }

    @available(*, deprecated, message: "Use `Base8.encodedString(Array(str.utf8), pad:)`.")
    public static func encode(_ str: String, options: Base8Options...) -> String {
        _encode(str.utf8, options: options)
    }

    /// Variadic Overload
    @available(*, deprecated, message: "Use `Base8.encodedString(_:pad:)`.")
    public static func encode(_ d: Data, options: Base8Options...) -> String {
        _encode(d, options: options)
    }

    @available(*, deprecated, message: "Use `Base8.encodedString(_:pad:)`.")
    public static func encode(_ d: Data, options: [Base8Options]) -> String {
        _encode(d, options: options)
    }

    @available(*, deprecated, message: "Use `String(decoding: try Base8.decode(str), as: UTF8.self)`.")
    public static func decodeToString(_ string: String, using strEncoding: String.Encoding = .ascii) throws -> String {
        guard let str = String(data: Data(try decode(string.utf8)), encoding: strEncoding) else {
            throw BasesError.invalidStringEncoding
        }
        return str
    }

    @available(*, deprecated, message: "Use `Base8.decode(_:)`, which returns `[UInt8]`.")
    public static func decode(_ string: String) throws -> Data {
        Data(try decode(string.utf8))
    }

    /// Applies a pre-0.4.0 options bag, then encodes.
    ///
    /// Mirrors the old evaluation order: `.nullChar(.drop)` strips leading null bytes from
    /// the input, and any `.pad(false)` leaves the output unpadded.
    internal static func _encode(_ bytes: some Collection<UInt8>, options: [Base8Options]) -> String {
        var dropNulls = false
        var pad = PadOption.padded
        for option in options {
            switch option {
            case .nullChar(.drop): dropNulls = true
            case .nullChar: break
            case .pad(let padded): if !padded { pad = .unpadded }
            }
        }
        return dropNulls
            ? encodedString(bytes.drop(while: { $0 == 0 }), pad: pad)
            : encodedString(bytes, pad: pad)
    }
}

extension Data {

    /// Base8-encodes these bytes.
    @available(*, deprecated, message: "Use `Base8.encodedString(_:pad:)`.")
    public func base8Encoded(options: Base8.Base8Options...) -> String {
        Base8._encode(self, options: options)
    }

    /// Decodes a Base8 string into bytes.
    @available(*, deprecated, message: "Use `Base8.decode(_:)`.")
    public init(base8Encoded string: String) throws {
        self = Data(try Base8.decode(string.utf8))
    }
}
