// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed64x44

extension Sol {
    public struct UFixed64x44 {
        public var storage: Sol.UInt64
        public init() { storage = 0 }
        public init(storage: Sol.UInt64) { self.storage = storage }
    }
}

extension Sol.UFixed64x44: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 44 }
}

// MARK: - Sol.Fixed64x44

extension Sol {
    public struct Fixed64x44 {
        public var storage: Sol.Int64
        public init() { storage = 0 }
        public init(storage: Sol.Int64) { self.storage = storage }
    }
}

extension Sol.Fixed64x44: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 44 }
}

