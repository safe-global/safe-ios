// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed168x8

extension Sol {
    public struct UFixed168x8 {
        public var storage: Sol.UInt168
        public init() { storage = 0 }
        public init(storage: Sol.UInt168) { self.storage = storage }
    }
}

extension Sol.UFixed168x8: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 8 }
}

// MARK: - Sol.Fixed168x8

extension Sol {
    public struct Fixed168x8 {
        public var storage: Sol.Int168
        public init() { storage = 0 }
        public init(storage: Sol.Int168) { self.storage = storage }
    }
}

extension Sol.Fixed168x8: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 8 }
}

