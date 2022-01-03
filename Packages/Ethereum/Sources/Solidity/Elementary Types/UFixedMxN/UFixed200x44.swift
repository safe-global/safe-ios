// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed200x44

extension Sol {
    public struct UFixed200x44 {
        public var storage: Sol.UInt200
        public init() { storage = 0 }
        public init(storage: Sol.UInt200) { self.storage = storage }
    }
}

extension Sol.UFixed200x44: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 200 }
    public static var exponent: Int { 44 }
}

// MARK: - Sol.Fixed200x44

extension Sol {
    public struct Fixed200x44 {
        public var storage: Sol.Int200
        public init() { storage = 0 }
        public init(storage: Sol.Int200) { self.storage = storage }
    }
}

extension Sol.Fixed200x44: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 200 }
    public static var exponent: Int { 44 }
}

