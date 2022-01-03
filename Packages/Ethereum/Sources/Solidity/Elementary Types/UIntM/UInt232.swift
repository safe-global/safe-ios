// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt232

extension Sol {
    public struct UInt232 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt232: WordUnsignedInteger {
    public typealias Stride = Sol.Int232
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 232 }
}

extension Sol.UInt232: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int232

extension Sol {
    public struct Int232 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int232: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt232
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 232 }
}

extension Sol.Int232: SolInteger {
    // uses default implementation
}

