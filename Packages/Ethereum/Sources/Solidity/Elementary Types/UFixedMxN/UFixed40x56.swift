// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed40x56

extension Sol {
    public struct UFixed40x56 {
        public var storage: Sol.UInt40
        public init() { storage = 0 }
        public init(storage: Sol.UInt40) { self.storage = storage }
    }
}

extension Sol.UFixed40x56: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 40 }
    public static var exponent: Int { 56 }
}

// MARK: - Sol.Fixed40x56

extension Sol {
    public struct Fixed40x56 {
        public var storage: Sol.Int40
        public init() { storage = 0 }
        public init(storage: Sol.Int40) { self.storage = storage }
    }
}

extension Sol.Fixed40x56: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 40 }
    public static var exponent: Int { 56 }
}

