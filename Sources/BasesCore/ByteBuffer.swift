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

/// Runs `body` over `bytes` as one contiguous buffer.
///
/// Every codec in this package funnels through this, so its hot loop reads a concrete
/// `UnsafeBufferPointer<UInt8>` rather than iterating over a generic `Collection<UInt8>`.
/// That distinction is worth roughly an order of magnitude, a non-`@inlinable` generic
/// cannot specialize across a module boundary, so each element would otherwise be fetched
/// through a witness-table `Iterator.next()`, and `Data`'s iterator re-examines its
/// internal representation per byte.
///
/// `Data`, `Array`, `ArraySlice`, `ContiguousArray` and `String.UTF8View` (for a native
/// string) all provide contiguous storage directly. Anything else is copied into a
/// `ContiguousArray` once, which still beats per-element generic dispatch.
///
/// - Note: `body` cannot throw. `Collection.withContiguousStorageIfAvailable` is
///   `rethrows`, which erases a typed `throws(BasesError)` back to `any Error`, the
///   decoders therefore return a `Result` from `body` and unwrap it afterwards.
@inlinable
public func withByteBuffer<C: Collection<UInt8>, R>(
    _ bytes: C,
    _ body: (UnsafeBufferPointer<UInt8>) -> R
) -> R {
    if let result = bytes.withContiguousStorageIfAvailable(body) { return result }
    return ContiguousArray(bytes).withUnsafeBufferPointer(body)
}

/// Runs `body` over a string's UTF-8 bytes as one contiguous buffer.
///
/// See ``withByteBuffer(_:_:)-(C,_)``. Iterating `String.UTF8View` generically is the
/// slowest of all the input shapes, so the string-accepting decoders route through here.
@inlinable
public func withByteBuffer<S: StringProtocol, R>(
    _ string: S,
    _ body: (UnsafeBufferPointer<UInt8>) -> R
) -> R {
    if let result = string.utf8.withContiguousStorageIfAvailable(body) { return result }
    return ContiguousArray(string.utf8).withUnsafeBufferPointer(body)
}
