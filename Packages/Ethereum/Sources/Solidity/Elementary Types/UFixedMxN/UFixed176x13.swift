// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed176x13

extension Sol {
    public struct UFixed176x13 {
        public var storage: Sol.UInt176
        public init() { storage = 0 }
        public init(storage: Sol.UInt176) { self.storage = storage }
    }
}

extension Sol.UFixed176x13: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 176 }
    public static var exponent: Int { 13 }
}

// MARK: - Sol.Fixed176x13

extension Sol {
    public struct Fixed176x13 {
        public var storage: Sol.Int176
        public init() { storage = 0 }
        public init(storage: Sol.Int176) { self.storage = storage }
    }
}

extension Sol.Fixed176x13: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 176 }
    public static var exponent: Int { 13 }
}

