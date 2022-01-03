// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt256

extension Sol {
    public struct UInt256 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt256: WordUnsignedInteger {
    public typealias Stride = Sol.Int256
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 256 }
}

extension Sol.UInt256: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int256

extension Sol {
    public struct Int256 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int256: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt256
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 256 }
}

extension Sol.Int256: SolInteger {
    // uses default implementation
}

