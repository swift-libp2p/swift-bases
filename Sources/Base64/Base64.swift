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

/// Base64 encoding/decoding covering the four variants defined by the multibase spec.
///
/// The single-character multibase prefix (`m`, `M`, `u`, `U`) is *not* handled here — that
/// belongs to the multibase layer. This type produces/consumes the raw base64 payload for:
///
/// | multibase | variant     | padded |
/// |-----------|-------------|--------|
/// | `m`       | `.standard` | `false`|
/// | `M`       | `.standard` | `true` |
/// | `u`       | `.url`      | `false`|
/// | `U`       | `.url`      | `true` |
///
/// Decoding is padding-tolerant: it accepts input with or without trailing `=`, so the
/// unpadded (`m`/`u`) forms round-trip correctly.
public enum Base64 {
    public enum Error: Swift.Error {
        /// The input contains characters that are not valid for the selected base64 variant,
        /// or is otherwise malformed.
        case invalidCharacter
        /// A `String` could not be produced/consumed with the requested `String.Encoding`.
        case invalidStringEncoding
    }

    /// Which base64 alphabet to use.
    public enum Variant {
        /// Standard RFC 4648 alphabet using `+` and `/` (multibase `m` / `M`).
        case standard
        /// URL- and filename-safe alphabet using `-` and `_` (multibase `u` / `U`).
        case url
    }

    // MARK: - Encoding

    /// Encodes bytes as a base64 string in the given variant, optionally padded.
    public static func encode(_ data: Data, variant: Variant = .standard, pad: Bool = true) -> String {
        switch variant {
        case .standard: return data.base64Encoded(padded: pad)
        case .url: return data.base64URLEncoded(padded: pad)
        }
    }

    /// Encodes a string's UTF-8 bytes as a base64 string in the given variant.
    public static func encode(_ str: String, variant: Variant = .standard, pad: Bool = true) -> String {
        encode(Data(str.utf8), variant: variant, pad: pad)
    }

    // MARK: - Decoding

    /// Decodes a base64 string (padded or unpadded) in the given variant into bytes.
    ///
    /// Throws `Base64.Error.invalidCharacter` if the input isn't valid base64 for `variant`.
    public static func decode(_ string: String, variant: Variant = .standard) throws -> Data {
        var normalized = string
        if variant == .url {
            normalized =
                normalized
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
        }
        // Multibase's unpadded forms (`m`/`u`) omit trailing `=`, so restore padding first.
        normalized = normalized.base64CompliantString
        guard let data = Data(base64Encoded: normalized) else {
            throw Base64.Error.invalidCharacter
        }
        return data
    }

    /// Decodes a base64 string and interprets the resulting bytes as a `String`.
    public static func decodeToString(
        _ string: String,
        variant: Variant = .standard,
        using strEncoding: String.Encoding = .utf8
    ) throws -> String {
        guard let str = String(data: try decode(string, variant: variant), encoding: strEncoding) else {
            throw Base64.Error.invalidStringEncoding
        }
        return str
    }
}

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

    /// Decodes a URL-safe base64 string (padded or unpadded) into bytes.
    ///
    /// Throws `Base64.Error.invalidCharacter` on malformed input. (Previously a failable
    /// initializer returning `nil`; now throwing for consistency with the other decoders.)
    public init(base64URLEncoded string: String) throws {
        self = try Base64.decode(string, variant: .url)
    }

    /// Decodes URL-safe base64 held as UTF-8 `Data` into the decoded bytes.
    public init(base64URLEncoded data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Base64.Error.invalidStringEncoding
        }
        self = try Base64.decode(string, variant: .url)
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
