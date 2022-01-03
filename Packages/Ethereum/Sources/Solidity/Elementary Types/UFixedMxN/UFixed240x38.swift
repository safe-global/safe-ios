// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed240x38

extension Sol {
    public struct UFixed240x38 {
        public var storage: Sol.UInt240
        public init() { storage = 0 }
        public init(storage: Sol.UInt240) { self.storage = storage }
    }
}

extension Sol.UFixed240x38: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 240 }
    public static var exponent: Int { 38 }
}

// MARK: - Sol.Fixed240x38

extension Sol {
    public struct Fixed240x38 {
        public var storage: Sol.Int240
        public init() { storage = 0 }
        public init(storage: Sol.Int240) { self.storage = storage }
    }
}

extension Sol.Fixed240x38: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 240 }
    public static var exponent: Int { 38 }
}

