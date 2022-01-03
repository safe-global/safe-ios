// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt16

extension Sol {
    public struct UInt16 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt16: WordUnsignedInteger {
    public typealias Stride = Sol.Int16
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 16 }
}

extension Sol.UInt16: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int16

extension Sol {
    public struct Int16 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int16: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt16
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 16 }
}

extension Sol.Int16: SolInteger {
    // uses default implementation
}

