// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed56x28

extension Sol {
    public struct UFixed56x28 {
        public var storage: Sol.UInt56
        public init() { storage = 0 }
        public init(storage: Sol.UInt56) { self.storage = storage }
    }
}

extension Sol.UFixed56x28: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 56 }
    public static var exponent: Int { 28 }
}

// MARK: - Sol.Fixed56x28

extension Sol {
    public struct Fixed56x28 {
        public var storage: Sol.Int56
        public init() { storage = 0 }
        public init(storage: Sol.Int56) { self.storage = storage }
    }
}

extension Sol.Fixed56x28: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 56 }
    public static var exponent: Int { 28 }
}

