// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed184x23

extension Sol {
    public struct UFixed184x23 {
        public var storage: Sol.UInt184
        public init() { storage = 0 }
        public init(storage: Sol.UInt184) { self.storage = storage }
    }
}

extension Sol.UFixed184x23: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 184 }
    public static var exponent: Int { 23 }
}

// MARK: - Sol.Fixed184x23

extension Sol {
    public struct Fixed184x23 {
        public var storage: Sol.Int184
        public init() { storage = 0 }
        public init(storage: Sol.Int184) { self.storage = storage }
    }
}

extension Sol.Fixed184x23: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 184 }
    public static var exponent: Int { 23 }
}

