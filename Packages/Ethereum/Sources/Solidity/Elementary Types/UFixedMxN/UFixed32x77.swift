// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed32x77

extension Sol {
    public struct UFixed32x77 {
        public var storage: Sol.UInt32
        public init() { storage = 0 }
        public init(storage: Sol.UInt32) { self.storage = storage }
    }
}

extension Sol.UFixed32x77: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 32 }
    public static var exponent: Int { 77 }
}

// MARK: - Sol.Fixed32x77

extension Sol {
    public struct Fixed32x77 {
        public var storage: Sol.Int32
        public init() { storage = 0 }
        public init(storage: Sol.Int32) { self.storage = storage }
    }
}

extension Sol.Fixed32x77: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 32 }
    public static var exponent: Int { 77 }
}

