// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed144x59

extension Sol {
    public struct UFixed144x59 {
        public var storage: Sol.UInt144
        public init() { storage = 0 }
        public init(storage: Sol.UInt144) { self.storage = storage }
    }
}

extension Sol.UFixed144x59: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 144 }
    public static var exponent: Int { 59 }
}

// MARK: - Sol.Fixed144x59

extension Sol {
    public struct Fixed144x59 {
        public var storage: Sol.Int144
        public init() { storage = 0 }
        public init(storage: Sol.Int144) { self.storage = storage }
    }
}

extension Sol.Fixed144x59: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 144 }
    public static var exponent: Int { 59 }
}

