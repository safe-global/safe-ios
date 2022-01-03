// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed136x46

extension Sol {
    public struct UFixed136x46 {
        public var storage: Sol.UInt136
        public init() { storage = 0 }
        public init(storage: Sol.UInt136) { self.storage = storage }
    }
}

extension Sol.UFixed136x46: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 136 }
    public static var exponent: Int { 46 }
}

// MARK: - Sol.Fixed136x46

extension Sol {
    public struct Fixed136x46 {
        public var storage: Sol.Int136
        public init() { storage = 0 }
        public init(storage: Sol.Int136) { self.storage = storage }
    }
}

extension Sol.Fixed136x46: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 136 }
    public static var exponent: Int { 46 }
}

