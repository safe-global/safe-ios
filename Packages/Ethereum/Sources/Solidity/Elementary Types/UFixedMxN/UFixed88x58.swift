// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed88x58

extension Sol {
    public struct UFixed88x58 {
        public var storage: Sol.UInt88
        public init() { storage = 0 }
        public init(storage: Sol.UInt88) { self.storage = storage }
    }
}

extension Sol.UFixed88x58: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 88 }
    public static var exponent: Int { 58 }
}

// MARK: - Sol.Fixed88x58

extension Sol {
    public struct Fixed88x58 {
        public var storage: Sol.Int88
        public init() { storage = 0 }
        public init(storage: Sol.Int88) { self.storage = storage }
    }
}

extension Sol.Fixed88x58: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 88 }
    public static var exponent: Int { 58 }
}

