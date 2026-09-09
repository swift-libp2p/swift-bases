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

internal typealias EncodedChar = UInt8

/// The character that pads a partial final block.
internal let paddingCharacter: EncodedChar = Alphabet.paddingCharacter

extension Base8 {
    /// The base8 alphabet, `0` through `7`.
    public static let alphabet = Alphabet("01234567")
}
