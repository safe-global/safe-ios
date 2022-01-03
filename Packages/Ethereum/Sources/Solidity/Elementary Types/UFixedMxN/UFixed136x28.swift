// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed136x28

extension Sol {
    public struct UFixed136x28 {
        public var storage: Sol.UInt136
        public init() { storage = 0 }
        public init(storage: Sol.UInt136) { self.storage = storage }
    }
}

extension Sol.UFixed136x28: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 136 }
    public static var exponent: Int { 28 }
}

// MARK: - Sol.Fixed136x28

extension Sol {
    public struct Fixed136x28 {
        public var storage: Sol.Int136
        public init() { storage = 0 }
        public init(storage: Sol.Int136) { self.storage = storage }
    }
}

extension Sol.Fixed136x28: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 136 }
    public static var exponent: Int { 28 }
}

