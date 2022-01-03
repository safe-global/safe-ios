// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed8x74

extension Sol {
    public struct UFixed8x74 {
        public var storage: Sol.UInt8
        public init() { storage = 0 }
        public init(storage: Sol.UInt8) { self.storage = storage }
    }
}

extension Sol.UFixed8x74: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 8 }
    public static var exponent: Int { 74 }
}

// MARK: - Sol.Fixed8x74

extension Sol {
    public struct Fixed8x74 {
        public var storage: Sol.Int8
        public init() { storage = 0 }
        public init(storage: Sol.Int8) { self.storage = storage }
    }
}

extension Sol.Fixed8x74: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 8 }
    public static var exponent: Int { 74 }
}

