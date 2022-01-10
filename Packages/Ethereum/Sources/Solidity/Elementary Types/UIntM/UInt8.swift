// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt8

extension Sol {
    public struct UInt8 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt8: WordUnsignedInteger {
    public typealias Stride = Sol.Int8
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 8 }
}

extension Sol.UInt8: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int8

extension Sol {
    public struct Int8 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int8: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt8
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 8 }
}

extension Sol.Int8: SolInteger {
    // uses default implementation
}

