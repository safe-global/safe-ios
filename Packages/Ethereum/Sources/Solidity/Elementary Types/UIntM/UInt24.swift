// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt24

extension Sol {
    public struct UInt24 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt24: WordUnsignedInteger {
    public typealias Stride = Sol.Int24
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 24 }
}

extension Sol.UInt24: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int24

extension Sol {
    public struct Int24 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int24: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt24
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 24 }
}

extension Sol.Int24: SolInteger {
    // uses default implementation
}

