// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt32

extension Sol {
    public struct UInt32 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt32: WordUnsignedInteger {
    public typealias Stride = Sol.Int32
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 32 }
}

extension Sol.UInt32: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int32

extension Sol {
    public struct Int32 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int32: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt32
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 32 }
}

extension Sol.Int32: SolInteger {
    // uses default implementation
}

