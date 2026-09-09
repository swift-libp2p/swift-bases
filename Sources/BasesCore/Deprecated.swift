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
//  Compatibility shims for the pre-0.4.0 per-module error enums.
//
//  `Base32.Error`, `Base8.Error`, `Base64.Error`, `BaseX.BaseXError` and `Base2Error` are
//  now typealiases of `BasesError`. Their case names that `BasesError` does not spell the
//  same way are kept here so existing `catch` clauses and `#expect(throws:)` expectations
//  still compile and still match.
//

extension BasesError {

    /// The pre-0.4.0 `Base64.Error` / `BaseX.BaseXError` spelling of
    /// ``BasesError/nonAlphabetCharacter``.
    @available(*, deprecated, renamed: "nonAlphabetCharacter")
    public static var invalidCharacter: BasesError { .nonAlphabetCharacter }

    /// The pre-0.4.0 `Base8.Error` spelling of ``BasesError/nonAlphabetCharacter``.
    @available(*, deprecated, renamed: "nonAlphabetCharacter")
    public static var nonNumericCharacter: BasesError { .nonAlphabetCharacter }

    /// The pre-0.4.0 `Base2Error` spelling of ``BasesError/nonAlphabetCharacter``.
    @available(*, deprecated, renamed: "nonAlphabetCharacter")
    public static var invalidBinaryCharacter: BasesError { .nonAlphabetCharacter }

    /// The pre-0.4.0 `Base2Error` spelling of ``BasesError/invalidLength``.
    @available(*, deprecated, renamed: "invalidLength")
    public static var invalidBinaryLength: BasesError { .invalidLength }

    /// The pre-0.4.0 `Base32.Error` / `Base8.Error` spelling of
    /// ``BasesError/invalidStringEncoding``.
    @available(*, deprecated, renamed: "invalidStringEncoding")
    public static var nonAsciiCompliant: BasesError { .invalidStringEncoding }
}
