// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt248

extension Sol {
    public struct UInt248 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt248: WordUnsignedInteger {
    public typealias Stride = Sol.Int248
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 248 }
}

extension Sol.UInt248: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int248

extension Sol {
    public struct Int248 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int248: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt248
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 248 }
}

extension Sol.Int248: SolInteger {
    // uses default implementation
}

