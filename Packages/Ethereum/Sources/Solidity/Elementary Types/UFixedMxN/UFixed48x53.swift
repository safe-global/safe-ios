// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed48x53

extension Sol {
    public struct UFixed48x53 {
        public var storage: Sol.UInt48
        public init() { storage = 0 }
        public init(storage: Sol.UInt48) { self.storage = storage }
    }
}

extension Sol.UFixed48x53: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 48 }
    public static var exponent: Int { 53 }
}

// MARK: - Sol.Fixed48x53

extension Sol {
    public struct Fixed48x53 {
        public var storage: Sol.Int48
        public init() { storage = 0 }
        public init(storage: Sol.Int48) { self.storage = storage }
    }
}

extension Sol.Fixed48x53: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 48 }
    public static var exponent: Int { 53 }
}

