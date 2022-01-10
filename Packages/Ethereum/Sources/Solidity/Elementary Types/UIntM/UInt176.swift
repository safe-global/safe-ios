// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt176

extension Sol {
    public struct UInt176 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt176: WordUnsignedInteger {
    public typealias Stride = Sol.Int176
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 176 }
}

extension Sol.UInt176: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int176

extension Sol {
    public struct Int176 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int176: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt176
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 176 }
}

extension Sol.Int176: SolInteger {
    // uses default implementation
}

