// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt72

extension Sol {
    public struct UInt72 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt72: WordUnsignedInteger {
    public typealias Stride = Sol.Int72
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 72 }
}

extension Sol.UInt72: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int72

extension Sol {
    public struct Int72 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int72: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt72
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 72 }
}

extension Sol.Int72: SolInteger {
    // uses default implementation
}

