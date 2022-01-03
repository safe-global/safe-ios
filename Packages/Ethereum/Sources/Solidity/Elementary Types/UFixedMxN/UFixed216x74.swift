// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed216x74

extension Sol {
    public struct UFixed216x74 {
        public var storage: Sol.UInt216
        public init() { storage = 0 }
        public init(storage: Sol.UInt216) { self.storage = storage }
    }
}

extension Sol.UFixed216x74: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 216 }
    public static var exponent: Int { 74 }
}

// MARK: - Sol.Fixed216x74

extension Sol {
    public struct Fixed216x74 {
        public var storage: Sol.Int216
        public init() { storage = 0 }
        public init(storage: Sol.Int216) { self.storage = storage }
    }
}

extension Sol.Fixed216x74: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 216 }
    public static var exponent: Int { 74 }
}

