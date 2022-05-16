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

#### Heads up ‼️
- This library was built quickly and dirty as part of a larger project.
- This library hasn't been extensively tested! I'm sure theres more performant and safe and accurate ways to perform the encodings/decodings.  
- I wouldn't use this in production until you've vetted it yourself! 

#### For more details see 
- [Multiformats / Mulitbase Spec](https://github.com/multiformats/multibase/blob/master/README.md)


## Install

Include the following dependency in your Package.swift file
```Swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/swift-libp2p/swift-bases.git", .upToNextMajor(from: "0.0.1"))
    ],
    ...
    targets: [
        .target(
            ...
            dependencies: [
                .product(name:  "Base2", package: "swift-bases"),
                .product(name:  "Base8", package: "swift-bases"),
                .product(name:  "BaseX", package: "swift-bases"),
                .product(name: "Base32", package: "swift-bases"),
                .product(name: "Base64", package: "swift-bases")
            ]),
    ]
    ...
)
```

## Usage

### Example

```Swift
import Base2

let binaryEncoded = "Hello World".binaryEncoded(using: .utf8, spacing: true) // -> "01001000 01100101 01101100 01101100 01101111 00100000 01010111 01101111 01110010 01101100 01100100"
let decoded = binaryEncoded.binaryDecodedString // -> optional("Hello World")


import Base8

let base8Encoded = Base8.encode("hello world") // -> 320625543306744035667562330620==
let base8Decoded = Base8.decode("320625543306744035667562330620") // -> "hello world"


import BaseX

/// Base10
let base10Encoded = try BaseX.encode("Hello World", into: .base10Decimal) // -> 87521618088882533792115812
let base10Decoded:String = try BaseX.decode("87521618088882533792115812", as: .base10Decimal) // -> Hello World

/// Base16 (HEX) Lowercased
let base16LEncoded = try BaseX.encode("Hello World", into: .base16Hex) // -> 48656c6c6f20576f726c64
let base16LDecoded:String = try BaseX.decode("48656c6c6f20576f726c64", as: .base16Hex) // -> Hello World

/// Base16 (HEX) Uppercased
let base16UEncoded = try BaseX.encode("Hello World", into: .base16HexUpper) // -> 48656C6C6F20576F726C64
let base16UDecoded:String = try BaseX.decode("48656C6C6F20576F726C64", as: .base16HexUpper) // -> Hello World

/// Base36 Lowercased
let base36LEncoded = try BaseX.encode("Hello World", into: .base36) // -> azw5bz2xp56m4qyck
let base36LDecoded:String = try BaseX.decode("azw5bz2xp56m4qyck", as: .base36) // -> Hello World

/// Base36 Uppercased
let base36UEncoded = try BaseX.encode("Hello World", into: .base36Upper) // -> AZW5BZ2XP56M4QYCK
let base36UDecoded:String = try BaseX.decode("AZW5BZ2XP56M4QYCK", as: .base36Upper) // -> Hello World

/// Base58BTC
let base58BTCEncoded = try BaseX.encode("Hello World", into: .base58BTC) // -> JxF12TrwUP45BMd
let base58BTCDecoded:String = try BaseX.decode("JxF12TrwUP45BMd", as: .base58BTC) // -> Hello World

/// Base58Flickr
let base58FlickrEncoded = try BaseX.encode("Hello World", into: .base58Flickr) // -> iXf12sRWto45bmC
let base58FlickrDecoded:String = try BaseX.decode("iXf12sRWto45bmC", as: .base58Flickr) // -> Hello World


import Base32

/// Standard Base32 (Uppercased w/ padding)
Base32.encode("hello world") // -> "NBSWY3DPEB3W64TMMQ======"

/// Lowercased
Base32.encode("hello world", options: .letterCase(.lower), .pad(true)) // -> "nbswy3dpeb3w64tmmq======"

/// Lowercased without padding
Base32.encode("hello world", options: .letterCase(.lower), .pad(false)) // -> "nbswy3dpeb3w64tmmq"

/// Also includes 

/// Hex variants
Base32.encode("hello world", variant: .hex, options: .letterCase(.lower), .pad(false)) // -> "d1imor3f41rmusjccg"

/// and Z variants
Base32.encode("hello world", variant: .z, options: .letterCase(.lower), .pad(false)) // -> "pb1sa5dxrb5s6hucco"

/// Decoding
try Base32.decode("d1imor3f41rmusjccg", variant: .hex) // -> "hello world"

```

### API
```Swift

/// Base2
String.binaryEncoded(using encoding:String.Encoding = .utf8, byteSpacing:Bool = false) -> String?
String.binaryDecodedString -> String?

Data(binaryString:String)
Data.binaryEncoded(byteSpacing:Bool = false) -> String

Array<UInt8>(binaryString:String)
Array<UInt8>.binaryEncoded(byteSpacing:Bool = false) -> String


/// Base8
Base8.encode(_ str:String, options:Base8Options...) -> String
Base8.decode(_ string: String) throws -> Data
Base8.decodeToString(_ string: String, using:String.Encoding = .ascii) throws -> String


/// BaseX (10, 16, 36, 58)
BaseX.encode(_ str:String, into base:BaseX.Alphabets, using encoding: String.Encoding = .utf8) throws -> String
BaseX.encode(_ data:Data, into base:BaseX.Alphabets) -> String


/// Base32 
Base32.encode(_ str:String, variant:Variant = .standard, options:Base32Options...) -> String
Base32.encode(_ data:Data, variant:Variant = .standard, options:Base32Options...) -> String
Base32.decode(_ string: String, variant:Variant = .standard) throws -> Data
Base32.decodeToString(_ string:String, variant:Variant = .standard, using:String.Encoding = .ascii) throws -> String

/// Base64
String.base64CompliantString // Ensures the base64 string is padded correctly
Data.base64URLEncoded(padded:Bool = true) -> String // Swaps "/" with "_", and "+" with "-"
Data.base64Encoded(padded:Bool = true) -> String
Data?(base64URLEncoded: String)

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
