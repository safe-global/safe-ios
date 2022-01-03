// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt208

extension Sol {
    public struct UInt208 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt208: WordUnsignedInteger {
    public typealias Stride = Sol.Int208
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 208 }
}

extension Sol.UInt208: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int208

extension Sol {
    public struct Int208 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int208: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt208
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 208 }
}

extension Sol.Int208: SolInteger {
    // uses default implementation
}

