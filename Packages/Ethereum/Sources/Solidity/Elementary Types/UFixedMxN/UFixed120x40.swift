// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed120x40

extension Sol {
    public struct UFixed120x40 {
        public var storage: Sol.UInt120
        public init() { storage = 0 }
        public init(storage: Sol.UInt120) { self.storage = storage }
    }
}

extension Sol.UFixed120x40: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 120 }
    public static var exponent: Int { 40 }
}

// MARK: - Sol.Fixed120x40

extension Sol {
    public struct Fixed120x40 {
        public var storage: Sol.Int120
        public init() { storage = 0 }
        public init(storage: Sol.Int120) { self.storage = storage }
    }
}

extension Sol.Fixed120x40: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 120 }
    public static var exponent: Int { 40 }
}

