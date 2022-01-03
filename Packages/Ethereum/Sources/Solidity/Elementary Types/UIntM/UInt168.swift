// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt168

extension Sol {
    public struct UInt168 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt168: WordUnsignedInteger {
    public typealias Stride = Sol.Int168
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 168 }
}

extension Sol.UInt168: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int168

extension Sol {
    public struct Int168 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int168: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt168
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 168 }
}

extension Sol.Int168: SolInteger {
    // uses default implementation
}

