// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed24x66

extension Sol {
    public struct UFixed24x66 {
        public var storage: Sol.UInt24
        public init() { storage = 0 }
        public init(storage: Sol.UInt24) { self.storage = storage }
    }
}

extension Sol.UFixed24x66: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 24 }
    public static var exponent: Int { 66 }
}

// MARK: - Sol.Fixed24x66

extension Sol {
    public struct Fixed24x66 {
        public var storage: Sol.Int24
        public init() { storage = 0 }
        public init(storage: Sol.Int24) { self.storage = storage }
    }
}

extension Sol.Fixed24x66: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 24 }
    public static var exponent: Int { 66 }
}

