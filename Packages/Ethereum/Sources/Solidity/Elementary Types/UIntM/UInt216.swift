// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt216

extension Sol {
    public struct UInt216 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt216: WordUnsignedInteger {
    public typealias Stride = Sol.Int216
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 216 }
}

extension Sol.UInt216: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int216

extension Sol {
    public struct Int216 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int216: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt216
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 216 }
}

extension Sol.Int216: SolInteger {
    // uses default implementation
}

