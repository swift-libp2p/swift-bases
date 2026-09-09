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

/// The single error type reported by every base encoder and decoder.
public enum BasesError: Error, Hashable, Sendable {

    /// The input contains a character that is not in the encoding alphabet.
    ///
    /// Padding characters that appear anywhere other than the end of the input are
    /// reported this way too.
    case nonAlphabetCharacter

    /// The input ends with an incomplete encoded block.
    ///
    /// The trailing group of characters holds a number of bits that no whole number of
    /// bytes could have produced.
    case incompleteBlock

    /// The final encoded character carries non-zero bits that the decoded bytes cannot hold.
    ///
    /// See [RFC 4648 §3.5](https://tools.ietf.org/html/rfc4648#section-3.5).
    case strayBits

    /// The input's length cannot represent a whole number of bytes.
    ///
    /// Reported by the fixed-width encodings (base2, base16) where every byte maps onto an
    /// exact number of characters.
    case invalidLength

    /// Bytes could not be produced from, or interpreted as, a `String` with the requested
    /// `String.Encoding`.
    case invalidStringEncoding
}

extension BasesError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nonAlphabetCharacter:
            "the input contains a character that is not in the encoding alphabet"
        case .incompleteBlock:
            "the input ends with an incomplete encoded block"
        case .strayBits:
            "the final encoded character carries non-zero bits that the decoded bytes cannot hold"
        case .invalidLength:
            "the input's length does not represent a whole number of bytes"
        case .invalidStringEncoding:
            "the bytes could not be produced from, or interpreted as, a String with the requested encoding"
        }
    }
}
