# SwiftBases

[![](https://img.shields.io/badge/made%20by-Breth-blue.svg?style=flat-square)](https://breth.app)
[![](https://img.shields.io/badge/project-multiformats-blue.svg?style=flat-square)](https://github.com/multiformats/multiformats)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-blue.svg?style=flat-square)](https://github.com/apple/swift-package-manager)
![Build & Test (macos and linux)](https://github.com/swift-libp2p/swift-bases/actions/workflows/build+test.yml/badge.svg)

> SwiftBases is a collection of encoding and decoding algorithms for various common bases.

## Table of Contents

- [Overview](#overview)
- [Install](#install)
- [Usage](#usage)
  - [Example](#example)
  - [API](#api)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## Overview
This library was designed to support the [Multibase](https://github.com/swift-libp2p/swift-multibase.git) package. At the moment is contains support for encoding/decoding into base 2, 8, 10, 16, 32, 36, 58 and 64 with some common variants for certain bases.

Every base accepts `Collection<UInt8>` and returns `[UInt8]`, so slices encode without being copied first, and each alphabet is a cached `static let` carrying a 256 entry reverse lookup table. The pre-0.4.0 `Data`/`String` entry points still work as deprecated wrappers.

#### Heads up ‼️
- This library was built quickly and dirty as part of a larger project.
- This library hasn't been extensively tested! I'm sure theres more performant and safe and accurate ways to perform the encodings/decodings.  
- I wouldn't use this in production until you've vetted it yourself! 

#### For more details see 
- [Multiformats / Mulitbase Spec](https://github.com/multiformats/multibase)


## Install

Include the following dependency in your Package.swift file
```Swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/swift-libp2p/swift-bases.git", .upToNextMinor(from: "0.4.0"))
    ],
    ...
    targets: [
        .target(
            ...
            dependencies: [
                // `Bases` re-exports every base module. Depend on the individual
                // products instead if you only need one or two.
                .product(name: "Bases", package: "swift-bases")
            ]),
    ]
    ...
)
```

The individual products are `Base2`, `Base8`, `BaseX`, `Base32`, `Base64`, and `BasesCore` (the shared `Alphabet`, `BasesError`, and options types, which every base module re-exports).

## Usage

### Example

Every encoder accepts a collection of bytes and every decoder returns `[UInt8]`. Use
`encodedString(_:)` when you want a `String` out, and pass a `String` to `decode(_:)` when
you have text to decode.

```Swift
import Bases  // or the individual base modules

let helloWorld = Array("Hello World".utf8)
let helloworld = Array("hello world".utf8)


/// Base2

Base2.encodedString(helloWorld, byteSpacing: true) // -> "01001000 01100101 01101100 01101100 01101111 00100000 01010111 01101111 01110010 01101100 01100100"
let base2Decoded: [UInt8] = try Base2.decode("01001000 01100101") // -> [0x48, 0x65]


/// Base8

Base8.encodedString(helloworld)                    // -> "320625543306744035667562330620=="
Base8.encodedString(helloworld, pad: .unpadded)    // -> "320625543306744035667562330620"
let base8Decoded: [UInt8] = try Base8.decode("320625543306744035667562330620") // -> the bytes of "hello world"


/// BaseX (10, 16, 36, 58)

/// Base10
BaseX.encodedString(helloWorld, into: .base10Decimal)              // -> 87521618088882533792115812
let base10Decoded: [UInt8] = try BaseX.decode("87521618088882533792115812", as: .base10Decimal) // -> Hello World

/// Base16 (HEX) Lowercased
BaseX.encodedString(helloWorld, into: .base16Hex)              // -> 48656c6c6f20576f726c64
try BaseX.decode(Array("48656c6c6f20576f726c64".utf8), as: .base16Hex)      // -> Hello World

/// Base16 (HEX) Uppercased
BaseX.encodedString(helloWorld, into: .base16HexUpper)         // -> 48656C6C6F20576F726C64
try BaseX.decode(Array("48656C6C6F20576F726C64".utf8), as: .base16HexUpper) // -> Hello World

/// Base36 Lowercased
BaseX.encodedString(helloWorld, into: .base36)                 // -> azw5bz2xp56m4qyck
try BaseX.decode(Array("azw5bz2xp56m4qyck".utf8), as: .base36)              // -> Hello World

/// Base36 Uppercased
BaseX.encodedString(helloWorld, into: .base36Upper)            // -> AZW5BZ2XP56M4QYCK
try BaseX.decode(Array("AZW5BZ2XP56M4QYCK".utf8), as: .base36Upper)         // -> Hello World

/// Base16 and base36 decode either case, so there's no need to case-convert first
try BaseX.decode(Array("AZW5BZ2XP56M4QYCK".utf8), as: .base36)              // -> Hello World

/// Base58BTC
BaseX.encodedString(helloWorld, into: .base58BTC)              // -> JxF12TrwUP45BMd
try BaseX.decode(Array("JxF12TrwUP45BMd".utf8), as: .base58BTC)             // -> Hello World

/// Base58Flickr
BaseX.encodedString(helloWorld, into: .base58Flickr)           // -> iXf12sRWto45bmC
try BaseX.decode(Array("iXf12sRWto45bmC".utf8), as: .base58Flickr)          // -> Hello World


/// Base32

/// Standard Base32 (Uppercased w/ padding)
Base32.encodedString(helloworld) // -> "NBSWY3DPEB3W64TMMQ======"

/// Lowercased
Base32.encodedString(helloworld, letterCase: .lower) // -> "nbswy3dpeb3w64tmmq======"

/// Lowercased without padding
Base32.encodedString(helloworld, letterCase: .lower, pad: .unpadded) // -> "nbswy3dpeb3w64tmmq"

/// Also includes

/// Hex variants
Base32.encodedString(helloworld, variant: .hex, letterCase: .lower, pad: .unpadded) // -> "d1imor3f41rmusjccg"

/// and Z variants (whose natural case is lower)
Base32.encodedString(helloworld, variant: .z, pad: .unpadded) // -> "pb1sa5dxrb5s6hucco"

/// Decoding is case-insensitive and padding-tolerant for every variant
let base32Decoded: [UInt8] = try Base32.decode("d1imor3f41rmusjccg", variant: .hex) // -> the bytes of "hello world"


/// Base64 (multibase variants: m, M, u, U)

let greeting = Array("hi libp2p!".utf8)

/// Standard, padded (multibase `M`)
Base64.encodedString(greeting)                                  // -> "aGkgbGlicDJwIQ=="
/// Standard, no padding (multibase `m`)
Base64.encodedString(greeting, pad: .unpadded)                  // -> "aGkgbGlicDJwIQ"
/// URL-safe, no padding (multibase `u`)
Base64.encodedString(greeting, variant: .url, pad: .unpadded)   // -> "aGkgbGlicDJwIQ"

/// Decoding is padding-tolerant (accepts padded or unpadded input)
let base64Decoded: [UInt8] = try Base64.decode("aGkgbGlicDJwIQ") // -> the bytes of "hi libp2p!"


/// Slices encode without being copied first
let framed = Array("<<>>".utf8) + greeting
Base64.encodedString(framed.dropFirst(4), pad: .unpadded)       // -> "aGkgbGlicDJwIQ"

/// One error type, so a single catch covers every base
do {
    _ = try Base32.decode(Array("MZXW6YT!".utf8))
} catch {
    // `decode` is declared `throws(BasesError)`, so `error` is a `BasesError` here
    print(error == .nonAlphabetCharacter)
}
```

### API
```Swift

/// BasesCore — shared by, and re-exported from, every base module
enum BasesError: Error, Hashable, Sendable {
    case nonAlphabetCharacter, incompleteBlock, strayBits, invalidLength, invalidStringEncoding
}
enum LetterCase: Sendable, Hashable { case upper, lower }
enum PadOption:  Sendable, Hashable { case padded, unpadded }

struct Alphabet: Hashable, Sendable {
    init(_ characters:String, caseInsensitive:Bool = false, aliases:[UInt8: UInt8] = [:])
    var characters:[UInt8]      // the digits, in value order
    var decodingTable:[UInt8]   // 256 entries; `Alphabet.sentinel` where absent
    var characterString:String
    var radix:Int
    var leader:UInt8
    func character(encoding value:UInt8) -> UInt8
    func value(decoding character:UInt8) throws(BasesError) -> UInt8
    func contains(_ character:UInt8) -> Bool
    func uppercased() -> Alphabet
    func lowercased() -> Alphabet
}


/// Base2
Base2.encode(_ bytes:some Collection<UInt8>, byteSpacing:Bool = false) -> [UInt8]
Base2.encodedString(_ bytes:some Collection<UInt8>, byteSpacing:Bool = false) -> String
Base2.decode(_ characters:some Collection<UInt8>) throws(BasesError) -> [UInt8]
Base2.decode(_ string:some StringProtocol) throws(BasesError) -> [UInt8]
Base2.alphabet -> Alphabet

Collection<UInt8>.binaryEncoded(byteSpacing:Bool = false) -> String


/// Base8
Base8.encode(_ bytes:some Collection<UInt8>, pad:PadOption = .padded) -> [UInt8]
Base8.encodedString(_ bytes:some Collection<UInt8>, pad:PadOption = .padded) -> String
Base8.decode(_ characters:some Collection<UInt8>) throws(BasesError) -> [UInt8]
Base8.decode(_ string:some StringProtocol) throws(BasesError) -> [UInt8]
Base8.alphabet -> Alphabet


/// BaseX (10, 16, 36, 58)
BaseX.encode(_ bytes:some Collection<UInt8>, into base:BaseX.Alphabets) -> [UInt8]
BaseX.encodedString(_ bytes:some Collection<UInt8>, into base:BaseX.Alphabets) -> String
BaseX.decode(_ characters:some Collection<UInt8>, as base:BaseX.Alphabets) throws(BasesError) -> [UInt8]
BaseX.decode(_ string:some StringProtocol, as base:BaseX.Alphabets) throws(BasesError) -> [UInt8]
BaseX.Alphabets.alphabet -> Alphabet
// .base10Decimal .base16Hex .base16HexUpper .base36 .base36Upper .base58BTC .base58Flickr .custom(String)


/// Base32
Base32.encode(_ bytes:some Collection<UInt8>, variant:Variant = .standard, letterCase:LetterCase? = nil, pad:PadOption = .padded) -> [UInt8]
Base32.encodedString(_ bytes:some Collection<UInt8>, variant:Variant = .standard, letterCase:LetterCase? = nil, pad:PadOption = .padded) -> String
Base32.decode(_ characters:some Collection<UInt8>, variant:Variant = .standard) throws(BasesError) -> [UInt8]
Base32.decode(_ string:some StringProtocol, variant:Variant = .standard) throws(BasesError) -> [UInt8]
Variant.alphabet(_ letterCase:LetterCase? = nil) -> Alphabet  // .standard .hex .z
Variant.naturalCase -> LetterCase


/// Base64 (multibase variants: m, M, u, U)
Base64.encode(_ bytes:some Collection<UInt8>, variant:Base64.Variant = .standard, pad:PadOption = .padded) -> [UInt8]
Base64.encodedString(_ bytes:some Collection<UInt8>, variant:Base64.Variant = .standard, pad:PadOption = .padded) -> String
Base64.decode(_ characters:some Collection<UInt8>, variant:Base64.Variant = .standard) throws(BasesError) -> [UInt8]
Base64.decode(_ string:some StringProtocol, variant:Base64.Variant = .standard) throws(BasesError) -> [UInt8]
Base64.Variant.alphabet -> Alphabet  // .standard .url

```

## Contributing

Contributions are welcomed! This code is very much a proof of concept. I can guarantee you there's a better / safer way to accomplish the same results. Any suggestions, improvements, or even just critques, are welcome! 

Let's make this code better together! 🤝

## Credits

- [Matt Rubin's Bases Package](https://github.com/mattrubin/Bases)
- [Marcin Krzyżanowski's CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [SwiftRadix](https://github.com/orchetect/SwiftRadix)

## License

[MIT](LICENSE) © 2022 Breth Inc.
