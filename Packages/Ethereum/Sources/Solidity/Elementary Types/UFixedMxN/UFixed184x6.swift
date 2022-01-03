// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed184x6

extension Sol {
    public struct UFixed184x6 {
        public var storage: Sol.UInt184
        public init() { storage = 0 }
        public init(storage: Sol.UInt184) { self.storage = storage }
    }
}

extension Sol.UFixed184x6: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 184 }
    public static var exponent: Int { 6 }
}

// MARK: - Sol.Fixed184x6

extension Sol {
    public struct Fixed184x6 {
        public var storage: Sol.Int184
        public init() { storage = 0 }
        public init(storage: Sol.Int184) { self.storage = storage }
    }
}

extension Sol.Fixed184x6: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 184 }
    public static var exponent: Int { 6 }
}

