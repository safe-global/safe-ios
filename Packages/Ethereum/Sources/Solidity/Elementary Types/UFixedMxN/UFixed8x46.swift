// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed8x46

extension Sol {
    public struct UFixed8x46 {
        public var storage: Sol.UInt8
        public init() { storage = 0 }
        public init(storage: Sol.UInt8) { self.storage = storage }
    }
}

extension Sol.UFixed8x46: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 8 }
    public static var exponent: Int { 46 }
}

// MARK: - Sol.Fixed8x46

extension Sol {
    public struct Fixed8x46 {
        public var storage: Sol.Int8
        public init() { storage = 0 }
        public init(storage: Sol.Int8) { self.storage = storage }
    }
}

extension Sol.Fixed8x46: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 8 }
    public static var exponent: Int { 46 }
}

