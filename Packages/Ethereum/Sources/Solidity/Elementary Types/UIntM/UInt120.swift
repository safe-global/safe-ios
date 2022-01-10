// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt120

extension Sol {
    public struct UInt120 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt120: WordUnsignedInteger {
    public typealias Stride = Sol.Int120
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 120 }
}

extension Sol.UInt120: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int120

extension Sol {
    public struct Int120 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int120: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt120
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 120 }
}

extension Sol.Int120: SolInteger {
    // uses default implementation
}

