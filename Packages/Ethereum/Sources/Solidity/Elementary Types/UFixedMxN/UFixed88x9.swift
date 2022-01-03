// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed88x9

extension Sol {
    public struct UFixed88x9 {
        public var storage: Sol.UInt88
        public init() { storage = 0 }
        public init(storage: Sol.UInt88) { self.storage = storage }
    }
}

extension Sol.UFixed88x9: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 88 }
    public static var exponent: Int { 9 }
}

// MARK: - Sol.Fixed88x9

extension Sol {
    public struct Fixed88x9 {
        public var storage: Sol.Int88
        public init() { storage = 0 }
        public init(storage: Sol.Int88) { self.storage = storage }
    }
}

extension Sol.Fixed88x9: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 88 }
    public static var exponent: Int { 9 }
}

