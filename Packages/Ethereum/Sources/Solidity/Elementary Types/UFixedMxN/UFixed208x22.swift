// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed208x22

extension Sol {
    public struct UFixed208x22 {
        public var storage: Sol.UInt208
        public init() { storage = 0 }
        public init(storage: Sol.UInt208) { self.storage = storage }
    }
}

extension Sol.UFixed208x22: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 208 }
    public static var exponent: Int { 22 }
}

// MARK: - Sol.Fixed208x22

extension Sol {
    public struct Fixed208x22 {
        public var storage: Sol.Int208
        public init() { storage = 0 }
        public init(storage: Sol.Int208) { self.storage = storage }
    }
}

extension Sol.Fixed208x22: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 208 }
    public static var exponent: Int { 22 }
}

