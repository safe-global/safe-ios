// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed16x9

extension Sol {
    public struct UFixed16x9 {
        public var storage: Sol.UInt16
        public init() { storage = 0 }
        public init(storage: Sol.UInt16) { self.storage = storage }
    }
}

extension Sol.UFixed16x9: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 16 }
    public static var exponent: Int { 9 }
}

// MARK: - Sol.Fixed16x9

extension Sol {
    public struct Fixed16x9 {
        public var storage: Sol.Int16
        public init() { storage = 0 }
        public init(storage: Sol.Int16) { self.storage = storage }
    }
}

extension Sol.Fixed16x9: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 16 }
    public static var exponent: Int { 9 }
}

