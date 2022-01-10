// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt64

extension Sol {
    public struct UInt64 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt64: WordUnsignedInteger {
    public typealias Stride = Sol.Int64
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 64 }
}

extension Sol.UInt64: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int64

extension Sol {
    public struct Int64 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int64: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt64
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 64 }
}

extension Sol.Int64: SolInteger {
    // uses default implementation
}

