// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed168x68

extension Sol {
    public struct UFixed168x68 {
        public var storage: Sol.UInt168
        public init() { storage = 0 }
        public init(storage: Sol.UInt168) { self.storage = storage }
    }
}

extension Sol.UFixed168x68: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 68 }
}

// MARK: - Sol.Fixed168x68

extension Sol {
    public struct Fixed168x68 {
        public var storage: Sol.Int168
        public init() { storage = 0 }
        public init(storage: Sol.Int168) { self.storage = storage }
    }
}

extension Sol.Fixed168x68: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 168 }
    public static var exponent: Int { 68 }
}

