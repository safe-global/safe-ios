// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed176x64

extension Sol {
    public struct UFixed176x64 {
        public var storage: Sol.UInt176
        public init() { storage = 0 }
        public init(storage: Sol.UInt176) { self.storage = storage }
    }
}

extension Sol.UFixed176x64: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 176 }
    public static var exponent: Int { 64 }
}

// MARK: - Sol.Fixed176x64

extension Sol {
    public struct Fixed176x64 {
        public var storage: Sol.Int176
        public init() { storage = 0 }
        public init(storage: Sol.Int176) { self.storage = storage }
    }
}

extension Sol.Fixed176x64: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 176 }
    public static var exponent: Int { 64 }
}

