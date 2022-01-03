// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed80x40

extension Sol {
    public struct UFixed80x40 {
        public var storage: Sol.UInt80
        public init() { storage = 0 }
        public init(storage: Sol.UInt80) { self.storage = storage }
    }
}

extension Sol.UFixed80x40: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 80 }
    public static var exponent: Int { 40 }
}

// MARK: - Sol.Fixed80x40

extension Sol {
    public struct Fixed80x40 {
        public var storage: Sol.Int80
        public init() { storage = 0 }
        public init(storage: Sol.Int80) { self.storage = storage }
    }
}

extension Sol.Fixed80x40: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 80 }
    public static var exponent: Int { 40 }
}

