// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed128x13

extension Sol {
    public struct UFixed128x13 {
        public var storage: Sol.UInt128
        public init() { storage = 0 }
        public init(storage: Sol.UInt128) { self.storage = storage }
    }
}

extension Sol.UFixed128x13: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 128 }
    public static var exponent: Int { 13 }
}

// MARK: - Sol.Fixed128x13

extension Sol {
    public struct Fixed128x13 {
        public var storage: Sol.Int128
        public init() { storage = 0 }
        public init(storage: Sol.Int128) { self.storage = storage }
    }
}

extension Sol.Fixed128x13: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 128 }
    public static var exponent: Int { 13 }
}

