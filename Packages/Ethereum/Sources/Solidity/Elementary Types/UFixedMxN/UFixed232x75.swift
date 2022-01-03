// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed232x75

extension Sol {
    public struct UFixed232x75 {
        public var storage: Sol.UInt232
        public init() { storage = 0 }
        public init(storage: Sol.UInt232) { self.storage = storage }
    }
}

extension Sol.UFixed232x75: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 232 }
    public static var exponent: Int { 75 }
}

// MARK: - Sol.Fixed232x75

extension Sol {
    public struct Fixed232x75 {
        public var storage: Sol.Int232
        public init() { storage = 0 }
        public init(storage: Sol.Int232) { self.storage = storage }
    }
}

extension Sol.Fixed232x75: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 232 }
    public static var exponent: Int { 75 }
}

