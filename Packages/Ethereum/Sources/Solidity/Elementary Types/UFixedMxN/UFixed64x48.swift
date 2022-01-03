// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed64x48

extension Sol {
    public struct UFixed64x48 {
        public var storage: Sol.UInt64
        public init() { storage = 0 }
        public init(storage: Sol.UInt64) { self.storage = storage }
    }
}

extension Sol.UFixed64x48: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 48 }
}

// MARK: - Sol.Fixed64x48

extension Sol {
    public struct Fixed64x48 {
        public var storage: Sol.Int64
        public init() { storage = 0 }
        public init(storage: Sol.Int64) { self.storage = storage }
    }
}

extension Sol.Fixed64x48: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 64 }
    public static var exponent: Int { 48 }
}

