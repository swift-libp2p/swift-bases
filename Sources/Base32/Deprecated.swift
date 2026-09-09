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

@available(*, deprecated, renamed: "NullCharOption")
public typealias NullCharOpts = NullCharOption

/// The pre-0.4.0 options bag.
///
/// The byte-native entry points take the options as parameters instead:
/// `Base32.encode(bytes, variant: .z, letterCase: .lower, pad: .unpadded)`,
/// and leading null bytes are dropped by slicing the input,
/// `Base32.encode(bytes.drop(while: { $0 == 0 }))`.
public enum Base32Options: Sendable {
    case pad(Bool)
    case nullChar(NullCharOption)
    case letterCase(LetterCase)
}

extension Base32 {

    @available(*, deprecated, renamed: "BasesError")
    public typealias Error = BasesError

    @available(
        *,
        deprecated,
        message: "Use `Base32.encodedString(Array(str.utf8), variant:letterCase:pad:)`."
    )
    public static func encode(_ str: String, variant: Variant = .standard, options: Base32Options...) -> String {
        _encode(str.utf8, variant: variant, options: options)
    }

    @available(*, deprecated, message: "Use `Base32.encodedString(_:variant:letterCase:pad:)`.")
    public static func encode(_ data: Data, variant: Variant = .standard, options: Base32Options...) -> String {
        _encode(data, variant: variant, options: options)
    }

    @available(*, deprecated, message: "Use `Base32.encodedString(_:variant:letterCase:pad:)`.")
    public static func encode(
        _ d: Data,
        variant: Variant = .standard,
        options: [Base32Options] = [.letterCase(.upper), .pad(true), .nullChar(.encode)]
    ) -> String {
        _encode(d, variant: variant, options: options)
    }

    @available(*, deprecated, message: "Use `String(decoding: try Base32.decode(str), as: UTF8.self)`.")
    public static func decodeToString(
        _ string: String,
        variant: Variant = .standard,
        using strEncoding: String.Encoding = .ascii
    ) throws -> String {
        guard let str = String(data: Data(try decode(string.utf8, variant: variant)), encoding: strEncoding) else {
            throw BasesError.invalidStringEncoding
        }
        return str
    }

    @available(*, deprecated, message: "Use `Base32.decode(_:variant:)`, which returns `[UInt8]`.")
    public static func decode(_ string: String, variant: Variant = .standard) throws -> Data {
        Data(try decode(string.utf8, variant: variant))
    }

    /// Applies the pre-0.4.0 options, then encodes.
    ///
    /// Mirrors the old evaluation order: the last `.letterCase` wins, `.nullChar(.drop)`
    /// strips leading null bytes from the input, and any `.pad(false)` leaves the output
    /// unpadded. An empty options array means "the alphabet's own case, padded", which is
    /// what the old string-transform pipeline did when given nothing to apply.
    internal static func _encode(
        _ bytes: some Collection<UInt8>,
        variant: Variant,
        options: [Base32Options]
    ) -> String {
        var letterCase: LetterCase? = nil
        var dropNulls = false
        var pad = PadOption.padded
        for option in options {
            switch option {
            case .letterCase(let requested): letterCase = requested
            case .nullChar(.drop): dropNulls = true
            case .nullChar: break
            case .pad(let padded): if !padded { pad = .unpadded }
            }
        }
        return dropNulls
            ? encodedString(bytes.drop(while: { $0 == 0 }), variant: variant, letterCase: letterCase, pad: pad)
            : encodedString(bytes, variant: variant, letterCase: letterCase, pad: pad)
    }
}

extension Data {

    /// Base32-encodes these bytes.
    @available(*, deprecated, message: "Use `Base32.encodedString(_:variant:letterCase:pad:)`.")
    public func base32Encoded(variant: Base32.Variant = .standard, options: Base32Options...) -> String {
        Base32._encode(self, variant: variant, options: options)
    }

    /// Decodes a Base32 string into bytes.
    @available(*, deprecated, message: "Use `Base32.decode(_:variant:)`.")
    public init(base32Encoded string: String, variant: Base32.Variant = .standard) throws {
        self = Data(try Base32.decode(string.utf8, variant: variant))
    }
}
