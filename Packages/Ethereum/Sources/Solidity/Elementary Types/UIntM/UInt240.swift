// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt240

extension Sol {
    public struct UInt240 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt240: WordUnsignedInteger {
    public typealias Stride = Sol.Int240
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 240 }
}

extension Sol.UInt240: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int240

extension Sol {
    public struct Int240 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int240: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt240
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 240 }
}

extension Sol.Int240: SolInteger {
    // uses default implementation
}

