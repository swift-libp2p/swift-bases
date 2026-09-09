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

import BasesCore

extension BaseX {

    /// The positional alphabets `BaseX` can encode into.
    public enum Alphabets: Equatable, Sendable {
        case base10Decimal
        case base16Hex
        case base16HexUpper
        case base36
        case base36Upper
        case base58BTC
        case base58Flickr
        /// An arbitrary alphabet, given as its digits in value order.
        ///
        /// - Note: Unlike the cases above, a custom alphabet's reverse lookup table is
        ///   built on each use. Store `Alphabets` value in a `let` if you encode or
        ///   decode with it repeatedly.
        case custom(String)

        /// The alphabet this case names.
        public var alphabet: Alphabet {
            switch self {
            case .base10Decimal: Cached.base10Decimal
            case .base16Hex: Cached.base16Hex
            case .base16HexUpper: Cached.base16HexUpper
            case .base36: Cached.base36
            case .base36Upper: Cached.base36Upper
            case .base58BTC: Cached.base58BTC
            case .base58Flickr: Cached.base58Flickr
            case .custom(let characters): Alphabet(characters)
            }
        }

        /// Whether this is one of the base16 cases, which take the dedicated hex path
        /// rather than the general positional one.
        internal var isHex: Bool {
            self == .base16Hex || self == .base16HexUpper
        }
    }

    /// The cached alphabets.
    internal enum Cached {
        static let base10Decimal = Alphabet("0123456789")
        // The base16 and base36 alphabets are case insensitive
        static let base16Hex = Alphabet("0123456789abcdef", caseInsensitive: true)
        static let base16HexUpper = base16Hex.uppercased()
        static let base36 = Alphabet("0123456789abcdefghijklmnopqrstuvwxyz", caseInsensitive: true)
        static let base36Upper = base36.uppercased()
        static let base58BTC = Alphabet("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        static let base58Flickr = Alphabet("123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ")
    }
}
