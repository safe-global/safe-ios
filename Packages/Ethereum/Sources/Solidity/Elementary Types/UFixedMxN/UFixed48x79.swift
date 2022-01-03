// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed48x79

extension Sol {
    public struct UFixed48x79 {
        public var storage: Sol.UInt48
        public init() { storage = 0 }
        public init(storage: Sol.UInt48) { self.storage = storage }
    }
}

extension Sol.UFixed48x79: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 48 }
    public static var exponent: Int { 79 }
}

// MARK: - Sol.Fixed48x79

extension Sol {
    public struct Fixed48x79 {
        public var storage: Sol.Int48
        public init() { storage = 0 }
        public init(storage: Sol.Int48) { self.storage = storage }
    }
}

extension Sol.Fixed48x79: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 48 }
    public static var exponent: Int { 79 }
}

