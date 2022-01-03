// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed128x61

extension Sol {
    public struct UFixed128x61 {
        public var storage: Sol.UInt128
        public init() { storage = 0 }
        public init(storage: Sol.UInt128) { self.storage = storage }
    }
}

extension Sol.UFixed128x61: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 128 }
    public static var exponent: Int { 61 }
}

// MARK: - Sol.Fixed128x61

extension Sol {
    public struct Fixed128x61 {
        public var storage: Sol.Int128
        public init() { storage = 0 }
        public init(storage: Sol.Int128) { self.storage = storage }
    }
}

extension Sol.Fixed128x61: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 128 }
    public static var exponent: Int { 61 }
}

