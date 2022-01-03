// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt160

extension Sol {
    public struct UInt160 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt160: WordUnsignedInteger {
    public typealias Stride = Sol.Int160
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 160 }
}

extension Sol.UInt160: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int160

extension Sol {
    public struct Int160 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int160: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt160
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 160 }
}

extension Sol.Int160: SolInteger {
    // uses default implementation
}

