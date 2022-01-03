// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt200

extension Sol {
    public struct UInt200 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt200: WordUnsignedInteger {
    public typealias Stride = Sol.Int200
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 200 }
}

extension Sol.UInt200: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int200

extension Sol {
    public struct Int200 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int200: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt200
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 200 }
}

extension Sol.Int200: SolInteger {
    // uses default implementation
}

