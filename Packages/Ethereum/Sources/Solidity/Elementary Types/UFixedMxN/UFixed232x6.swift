// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed232x6

extension Sol {
    public struct UFixed232x6 {
        public var storage: Sol.UInt232
        public init() { storage = 0 }
        public init(storage: Sol.UInt232) { self.storage = storage }
    }
}

extension Sol.UFixed232x6: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 232 }
    public static var exponent: Int { 6 }
}

// MARK: - Sol.Fixed232x6

extension Sol {
    public struct Fixed232x6 {
        public var storage: Sol.Int232
        public init() { storage = 0 }
        public init(storage: Sol.Int232) { self.storage = storage }
    }
}

extension Sol.Fixed232x6: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 232 }
    public static var exponent: Int { 6 }
}

