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

@_exported import BasesCore

/// Base64 encoding/decoding covering the four variants defined by the multibase spec.
///
/// The single-character multibase prefix (`m`, `M`, `u`, `U`) is *not* handled here, that
/// belongs to the multibase layer. This type produces/consumes the raw base64 payload for:
///
/// ```
/// | multibase | variant     | padded |
/// |-----------|-------------|--------|
/// | `m`       | `.standard` | `false`|
/// | `M`       | `.standard` | `true` |
/// | `u`       | `.url`      | `false`|
/// | `U`       | `.url`      | `true` |
/// ```
///
/// Decoding is padding-agnostic, it accepts input with or without trailing `=`, so the
/// unpadded (`m`/`u`) forms round-trip correctly.
public enum Base64 {

    /// Which base64 alphabet to use.
    public enum Variant: Sendable {

        /// Standard RFC 4648 alphabet using `+` and `/` (multibase `m` / `M`).
        case standard

        /// URL (and filename) safe alphabet using `-` and `_` (multibase `u` / `U`).
        case url

        /// This variant's alphabet.
        ///
        /// - Note: ``url`` also *decodes* `+` and `/`, which keeps the pre-0.4.0 behavior
        ///   where URL-safe input was rewritten into the standard alphabet before being
        ///   handed to Foundation. Encoding only ever emits `-` and `_`.
        public var alphabet: Alphabet {
            switch self {
            case .standard: Alphabets.standard
            case .url: Alphabets.url
            }
        }
    }

    /// The cached base64 alphabets.
    internal enum Alphabets {
        static let standard = Alphabet(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        )
        static let url = Alphabet(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
            aliases: [UInt8(ascii: "+"): 62, UInt8(ascii: "/"): 63]
        )
    }

    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 3

    /// The size of a block after encoding, measured in characters.
    private static let encodedBlockSize = 4

    // MARK: - Encoding

    /// Encodes bytes as base64 characters in the given variant.
    ///
    /// - Returns: The encoded characters as ASCII bytes.
    public static func encode(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        pad: PadOption = .padded
    ) -> [UInt8] {
        let unencodedByteCount = bytes.count
        guard unencodedByteCount > 0 else { return [] }

        let alphabet = variant.alphabet
        let blockCount = (unencodedByteCount + unencodedBlockSize - 1) / unencodedBlockSize
        var characters = [UInt8](repeating: Alphabet.paddingCharacter, count: blockCount * encodedBlockSize)

        var accumulator: UInt32 = 0
        var filled = 0
        var offset = 0
        for byte in bytes {
            accumulator = accumulator << 8 | UInt32(byte)
            filled += 1
            if filled == unencodedBlockSize {
                characters[offset + 0] = alphabet.character(encoding: UInt8(accumulator >> 18 & 0x3F))
                characters[offset + 1] = alphabet.character(encoding: UInt8(accumulator >> 12 & 0x3F))
                characters[offset + 2] = alphabet.character(encoding: UInt8(accumulator >> 6 & 0x3F))
                characters[offset + 3] = alphabet.character(encoding: UInt8(accumulator & 0x3F))
                offset += encodedBlockSize
                accumulator = 0
                filled = 0
            }
        }

        switch filled {
        case 1:
            // 8 bits become two characters, the second carries 2 zero bits.
            let bits = accumulator << 16
            characters[offset + 0] = alphabet.character(encoding: UInt8(bits >> 18 & 0x3F))
            characters[offset + 1] = alphabet.character(encoding: UInt8(bits >> 12 & 0x3F))
            if pad == .unpadded { characters.removeLast(2) }
        case 2:
            // 16 bits become three characters, the third carries 4 zero bits.
            let bits = accumulator << 8
            characters[offset + 0] = alphabet.character(encoding: UInt8(bits >> 18 & 0x3F))
            characters[offset + 1] = alphabet.character(encoding: UInt8(bits >> 12 & 0x3F))
            characters[offset + 2] = alphabet.character(encoding: UInt8(bits >> 6 & 0x3F))
            if pad == .unpadded { characters.removeLast(1) }
        default:
            break
        }
        return characters
    }

    /// Encodes bytes as a base64 `String` in the given variant.
    public static func encodedString(
        _ bytes: some Collection<UInt8>,
        variant: Variant = .standard,
        pad: PadOption = .padded
    ) -> String {
        String(decoding: encode(bytes, variant: variant, pad: pad), as: UTF8.self)
    }

    // MARK: - Decoding

    /// Decodes base64 characters (padded or unpadded) in the given variant into bytes.
    ///
    /// - Throws:
    ///   - ``BasesError/nonAlphabetCharacter`` for a character outside the variant's alphabet
    ///   - ``BasesError/incompleteBlock`` if the final block holds a single character,
    ///     which no byte could have produced.
    ///
    /// - Note: Lenient about the unused low bits of a partial final block, matching the
    ///   behavior of the Foundation decoder this replaces.
    public static func decode(
        _ characters: some Collection<UInt8>,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        let alphabet = variant.alphabet
        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / encodedBlockSize * unencodedBlockSize + unencodedBlockSize)

        var accumulator: UInt32 = 0
        var filled = 0
        var sawPadding = false
        for character in characters {
            if character == Alphabet.paddingCharacter {
                sawPadding = true
                continue
            }
            // Padding only ever terminates the input; a character after it is malformed.
            guard !sawPadding else { throw BasesError.nonAlphabetCharacter }
            accumulator = accumulator << 6 | UInt32(try alphabet.value(decoding: character))
            filled += 1
            if filled == encodedBlockSize {
                bytes.append(UInt8(accumulator >> 16 & 0xFF))
                bytes.append(UInt8(accumulator >> 8 & 0xFF))
                bytes.append(UInt8(accumulator & 0xFF))
                accumulator = 0
                filled = 0
            }
        }

        switch filled {
        case 0:
            break
        case 2:
            bytes.append(UInt8(accumulator >> 4 & 0xFF))
        case 3:
            bytes.append(UInt8(accumulator >> 10 & 0xFF))
            bytes.append(UInt8(accumulator >> 2 & 0xFF))
        default:
            throw BasesError.incompleteBlock
        }
        return bytes
    }

    /// Decodes a base64 `String` (padded or unpadded) in the given variant into bytes.
    public static func decode(
        _ string: some StringProtocol,
        variant: Variant = .standard
    ) throws(BasesError) -> [UInt8] {
        try decode(string.utf8, variant: variant)
    }
}
