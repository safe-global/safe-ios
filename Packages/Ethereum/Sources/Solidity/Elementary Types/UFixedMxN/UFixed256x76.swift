// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed256x76

extension Sol {
    public struct UFixed256x76 {
        public var storage: Sol.UInt256
        public init() { storage = 0 }
        public init(storage: Sol.UInt256) { self.storage = storage }
    }
}

extension Sol.UFixed256x76: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 256 }
    public static var exponent: Int { 76 }
}

// MARK: - Sol.Fixed256x76

extension Sol {
    public struct Fixed256x76 {
        public var storage: Sol.Int256
        public init() { storage = 0 }
        public init(storage: Sol.Int256) { self.storage = storage }
    }
}

extension Sol.Fixed256x76: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 256 }
    public static var exponent: Int { 76 }
}

