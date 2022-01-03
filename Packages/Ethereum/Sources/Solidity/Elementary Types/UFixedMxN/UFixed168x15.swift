// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed168x15

extension Sol {
    public struct UFixed168x15 {
        public var storage: Sol.UInt168
        public init() { storage = 0 }
        public init(storage: Sol.UInt168) { self.storage = storage }
    }
}

extension Sol.UFixed168x15: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 15 }
}

// MARK: - Sol.Fixed168x15

extension Sol {
    public struct Fixed168x15 {
        public var storage: Sol.Int168
        public init() { storage = 0 }
        public init(storage: Sol.Int168) { self.storage = storage }
    }
}

extension Sol.Fixed168x15: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 15 }
}

