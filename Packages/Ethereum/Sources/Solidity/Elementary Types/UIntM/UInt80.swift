// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt80

extension Sol {
    public struct UInt80 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt80: WordUnsignedInteger {
    public typealias Stride = Sol.Int80
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 80 }
}

extension Sol.UInt80: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int80

extension Sol {
    public struct Int80 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int80: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt80
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 80 }
}

extension Sol.Int80: SolInteger {
    // uses default implementation
}

