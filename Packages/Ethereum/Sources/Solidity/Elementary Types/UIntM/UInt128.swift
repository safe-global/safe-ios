// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt128

extension Sol {
    public struct UInt128 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt128: WordUnsignedInteger {
    public typealias Stride = Sol.Int128
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 128 }
}

extension Sol.UInt128: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int128

extension Sol {
    public struct Int128 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int128: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt128
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 128 }
}

extension Sol.Int128: SolInteger {
    // uses default implementation
}

