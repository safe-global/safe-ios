// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed200x60

extension Sol {
    public struct UFixed200x60 {
        public var storage: Sol.UInt200
        public init() { storage = 0 }
        public init(storage: Sol.UInt200) { self.storage = storage }
    }
}

extension Sol.UFixed200x60: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 200 }
    public static var exponent: Int { 60 }
}

// MARK: - Sol.Fixed200x60

extension Sol {
    public struct Fixed200x60 {
        public var storage: Sol.Int200
        public init() { storage = 0 }
        public init(storage: Sol.Int200) { self.storage = storage }
    }
}

extension Sol.Fixed200x60: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 200 }
    public static var exponent: Int { 60 }
}

