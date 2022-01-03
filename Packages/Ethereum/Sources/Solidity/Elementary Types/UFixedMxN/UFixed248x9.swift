// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed248x9

extension Sol {
    public struct UFixed248x9 {
        public var storage: Sol.UInt248
        public init() { storage = 0 }
        public init(storage: Sol.UInt248) { self.storage = storage }
    }
}

extension Sol.UFixed248x9: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 248 }
    public static var exponent: Int { 9 }
}

// MARK: - Sol.Fixed248x9

extension Sol {
    public struct Fixed248x9 {
        public var storage: Sol.Int248
        public init() { storage = 0 }
        public init(storage: Sol.Int248) { self.storage = storage }
    }
}

extension Sol.Fixed248x9: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 248 }
    public static var exponent: Int { 9 }
}

