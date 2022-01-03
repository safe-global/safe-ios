// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed240x23

extension Sol {
    public struct UFixed240x23 {
        public var storage: Sol.UInt240
        public init() { storage = 0 }
        public init(storage: Sol.UInt240) { self.storage = storage }
    }
}

extension Sol.UFixed240x23: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 240 }
    public static var exponent: Int { 23 }
}

// MARK: - Sol.Fixed240x23

extension Sol {
    public struct Fixed240x23 {
        public var storage: Sol.Int240
        public init() { storage = 0 }
        public init(storage: Sol.Int240) { self.storage = storage }
    }
}

extension Sol.Fixed240x23: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 240 }
    public static var exponent: Int { 23 }
}

