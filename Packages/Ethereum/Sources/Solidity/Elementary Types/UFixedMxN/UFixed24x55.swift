// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed24x55

extension Sol {
    public struct UFixed24x55 {
        public var storage: Sol.UInt24
        public init() { storage = 0 }
        public init(storage: Sol.UInt24) { self.storage = storage }
    }
}

extension Sol.UFixed24x55: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 24 }
    public static var exponent: Int { 55 }
}

// MARK: - Sol.Fixed24x55

extension Sol {
    public struct Fixed24x55 {
        public var storage: Sol.Int24
        public init() { storage = 0 }
        public init(storage: Sol.Int24) { self.storage = storage }
    }
}

extension Sol.Fixed24x55: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 24 }
    public static var exponent: Int { 55 }
}

