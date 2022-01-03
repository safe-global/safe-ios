// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt152

extension Sol {
    public struct UInt152 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt152: WordUnsignedInteger {
    public typealias Stride = Sol.Int152
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 152 }
}

extension Sol.UInt152: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int152

extension Sol {
    public struct Int152 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int152: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt152
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 152 }
}

extension Sol.Int152: SolInteger {
    // uses default implementation
}

