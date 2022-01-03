// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed192x31

extension Sol {
    public struct UFixed192x31 {
        public var storage: Sol.UInt192
        public init() { storage = 0 }
        public init(storage: Sol.UInt192) { self.storage = storage }
    }
}

extension Sol.UFixed192x31: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 192 }
    public static var exponent: Int { 31 }
}

// MARK: - Sol.Fixed192x31

extension Sol {
    public struct Fixed192x31 {
        public var storage: Sol.Int192
        public init() { storage = 0 }
        public init(storage: Sol.Int192) { self.storage = storage }
    }
}

extension Sol.Fixed192x31: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 192 }
    public static var exponent: Int { 31 }
}

