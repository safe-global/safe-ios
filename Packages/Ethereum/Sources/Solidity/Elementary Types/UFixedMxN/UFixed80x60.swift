// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed80x60

extension Sol {
    public struct UFixed80x60 {
        public var storage: Sol.UInt80
        public init() { storage = 0 }
        public init(storage: Sol.UInt80) { self.storage = storage }
    }
}

extension Sol.UFixed80x60: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 80 }
    public static var exponent: Int { 60 }
}

// MARK: - Sol.Fixed80x60

extension Sol {
    public struct Fixed80x60 {
        public var storage: Sol.Int80
        public init() { storage = 0 }
        public init(storage: Sol.Int80) { self.storage = storage }
    }
}

extension Sol.Fixed80x60: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 80 }
    public static var exponent: Int { 60 }
}

