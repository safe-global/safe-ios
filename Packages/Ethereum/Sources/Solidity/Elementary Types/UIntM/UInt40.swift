// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt40

extension Sol {
    public struct UInt40 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt40: WordUnsignedInteger {
    public typealias Stride = Sol.Int40
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 40 }
}

extension Sol.UInt40: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int40

extension Sol {
    public struct Int40 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int40: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt40
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 40 }
}

extension Sol.Int40: SolInteger {
    // uses default implementation
}

