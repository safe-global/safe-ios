// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt56

extension Sol {
    public struct UInt56 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt56: WordUnsignedInteger {
    public typealias Stride = Sol.Int56
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 56 }
}

extension Sol.UInt56: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int56

extension Sol {
    public struct Int56 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int56: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt56
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 56 }
}

extension Sol.Int56: SolInteger {
    // uses default implementation
}

