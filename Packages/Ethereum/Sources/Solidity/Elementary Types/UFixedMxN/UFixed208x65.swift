// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed208x65

extension Sol {
    public struct UFixed208x65 {
        public var storage: Sol.UInt208
        public init() { storage = 0 }
        public init(storage: Sol.UInt208) { self.storage = storage }
    }
}

extension Sol.UFixed208x65: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 208 }
    public static var exponent: Int { 65 }
}

// MARK: - Sol.Fixed208x65

extension Sol {
    public struct Fixed208x65 {
        public var storage: Sol.Int208
        public init() { storage = 0 }
        public init(storage: Sol.Int208) { self.storage = storage }
    }
}

extension Sol.Fixed208x65: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 208 }
    public static var exponent: Int { 65 }
}

