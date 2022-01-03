// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt224

extension Sol {
    public struct UInt224 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt224: WordUnsignedInteger {
    public typealias Stride = Sol.Int224
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 224 }
}

extension Sol.UInt224: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int224

extension Sol {
    public struct Int224 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int224: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt224
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 224 }
}

extension Sol.Int224: SolInteger {
    // uses default implementation
}

