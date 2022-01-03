// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed112x14

extension Sol {
    public struct UFixed112x14 {
        public var storage: Sol.UInt112
        public init() { storage = 0 }
        public init(storage: Sol.UInt112) { self.storage = storage }
    }
}

extension Sol.UFixed112x14: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 112 }
    public static var exponent: Int { 14 }
}

// MARK: - Sol.Fixed112x14

extension Sol {
    public struct Fixed112x14 {
        public var storage: Sol.Int112
        public init() { storage = 0 }
        public init(storage: Sol.Int112) { self.storage = storage }
    }
}

extension Sol.Fixed112x14: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 112 }
    public static var exponent: Int { 14 }
}

