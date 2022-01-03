// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed192x66

extension Sol {
    public struct UFixed192x66 {
        public var storage: Sol.UInt192
        public init() { storage = 0 }
        public init(storage: Sol.UInt192) { self.storage = storage }
    }
}

extension Sol.UFixed192x66: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 192 }
    public static var exponent: Int { 66 }
}

// MARK: - Sol.Fixed192x66

extension Sol {
    public struct Fixed192x66 {
        public var storage: Sol.Int192
        public init() { storage = 0 }
        public init(storage: Sol.Int192) { self.storage = storage }
    }
}

extension Sol.Fixed192x66: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 192 }
    public static var exponent: Int { 66 }
}

