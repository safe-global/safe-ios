// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed216x44

extension Sol {
    public struct UFixed216x44 {
        public var storage: Sol.UInt216
        public init() { storage = 0 }
        public init(storage: Sol.UInt216) { self.storage = storage }
    }
}

extension Sol.UFixed216x44: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 216 }
    public static var exponent: Int { 44 }
}

// MARK: - Sol.Fixed216x44

extension Sol {
    public struct Fixed216x44 {
        public var storage: Sol.Int216
        public init() { storage = 0 }
        public init(storage: Sol.Int216) { self.storage = storage }
    }
}

extension Sol.Fixed216x44: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 216 }
    public static var exponent: Int { 44 }
}

