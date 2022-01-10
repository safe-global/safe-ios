// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt192

extension Sol {
    public struct UInt192 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt192: WordUnsignedInteger {
    public typealias Stride = Sol.Int192
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 192 }
}

extension Sol.UInt192: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int192

extension Sol {
    public struct Int192 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int192: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt192
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 192 }
}

extension Sol.Int192: SolInteger {
    // uses default implementation
}

