// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt88

extension Sol {
    public struct UInt88 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt88: WordUnsignedInteger {
    public typealias Stride = Sol.Int88
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 88 }
}

extension Sol.UInt88: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int88

extension Sol {
    public struct Int88 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int88: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt88
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 88 }
}

extension Sol.Int88: SolInteger {
    // uses default implementation
}

