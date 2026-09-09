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

/// Which case an alphabet's letters are rendered in.
///
/// Only meaningful for the alphabets whose digits are letters of a single case
/// (base16, base32 and its variants, base36).
/// - Encoding picks the cased alphabet up front rather than case-converting the
///   output afterwards
/// - Decoding is case-insensitive for those alphabets either way.
public enum LetterCase: Sendable, Hashable {
    case upper
    case lower
}

/// Whether an encoding pads its final block out to a whole block.
public enum PadOption: Sendable, Hashable {
    /// Emit the alphabet's padding character (`=`) until the final block is complete.
    case padded
    
    /// Stop after the last significant character.
    case unpadded

    public init(_ padded: Bool) {
        self = padded ? .padded : .unpadded
    }

    public var isPadded: Bool { self == .padded }
}

/// What to do with leading null (`0x00`) bytes before encoding.
public enum NullCharOption: Sendable, Hashable {
    /// Drop leading null bytes, so they are not represented in the output at all.
    case drop
    
    /// Encode leading null bytes like any other byte.
    case encode
    
    /// Encode leading null bytes like any other byte.
    ///
    /// A synonym of ``encode``, kept because `Base8` spelled the option this way.
    case literal
}
