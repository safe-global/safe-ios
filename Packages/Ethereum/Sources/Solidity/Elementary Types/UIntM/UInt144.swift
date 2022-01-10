// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt144

extension Sol {
    public struct UInt144 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt144: WordUnsignedInteger {
    public typealias Stride = Sol.Int144
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 144 }
}

extension Sol.UInt144: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int144

extension Sol {
    public struct Int144 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int144: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt144
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 144 }
}

extension Sol.Int144: SolInteger {
    // uses default implementation
}

