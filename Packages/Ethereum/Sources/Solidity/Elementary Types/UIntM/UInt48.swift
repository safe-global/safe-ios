// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt48

extension Sol {
    public struct UInt48 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt48: WordUnsignedInteger {
    public typealias Stride = Sol.Int48
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 48 }
}

extension Sol.UInt48: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int48

extension Sol {
    public struct Int48 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int48: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt48
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 48 }
}

extension Sol.Int48: SolInteger {
    // uses default implementation
}

