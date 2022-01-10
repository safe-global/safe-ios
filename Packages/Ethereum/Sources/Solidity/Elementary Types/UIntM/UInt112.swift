// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt112

extension Sol {
    public struct UInt112 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt112: WordUnsignedInteger {
    public typealias Stride = Sol.Int112
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 112 }
}

extension Sol.UInt112: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int112

extension Sol {
    public struct Int112 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int112: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt112
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 112 }
}

extension Sol.Int112: SolInteger {
    // uses default implementation
}

