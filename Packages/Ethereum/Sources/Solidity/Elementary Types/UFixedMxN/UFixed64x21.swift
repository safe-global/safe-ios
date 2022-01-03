// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed64x21

extension Sol {
    public struct UFixed64x21 {
        public var storage: Sol.UInt64
        public init() { storage = 0 }
        public init(storage: Sol.UInt64) { self.storage = storage }
    }
}

extension Sol.UFixed64x21: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 21 }
}

// MARK: - Sol.Fixed64x21

extension Sol {
    public struct Fixed64x21 {
        public var storage: Sol.Int64
        public init() { storage = 0 }
        public init(storage: Sol.Int64) { self.storage = storage }
    }
}

extension Sol.Fixed64x21: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 21 }
}

