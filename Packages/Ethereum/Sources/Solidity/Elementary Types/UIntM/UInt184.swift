// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt184

extension Sol {
    public struct UInt184 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt184: WordUnsignedInteger {
    public typealias Stride = Sol.Int184
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 184 }
}

extension Sol.UInt184: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int184

extension Sol {
    public struct Int184 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int184: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt184
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 184 }
}

extension Sol.Int184: SolInteger {
    // uses default implementation
}

