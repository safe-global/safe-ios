// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt136

extension Sol {
    public struct UInt136 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt136: WordUnsignedInteger {
    public typealias Stride = Sol.Int136
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 136 }
}

extension Sol.UInt136: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int136

extension Sol {
    public struct Int136 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int136: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt136
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 136 }
}

extension Sol.Int136: SolInteger {
    // uses default implementation
}

