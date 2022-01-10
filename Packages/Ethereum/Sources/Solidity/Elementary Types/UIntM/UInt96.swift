// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt96

extension Sol {
    public struct UInt96 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt96: WordUnsignedInteger {
    public typealias Stride = Sol.Int96
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 96 }
}

extension Sol.UInt96: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int96

extension Sol {
    public struct Int96 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int96: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt96
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 96 }
}

extension Sol.Int96: SolInteger {
    // uses default implementation
}

