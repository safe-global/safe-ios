// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt104

extension Sol {
    public struct UInt104 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt104: WordUnsignedInteger {
    public typealias Stride = Sol.Int104
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 104 }
}

extension Sol.UInt104: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int104

extension Sol {
    public struct Int104 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int104: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt104
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 104 }
}

extension Sol.Int104: SolInteger {
    // uses default implementation
}

