// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed224x30

extension Sol {
    public struct UFixed224x30 {
        public var storage: Sol.UInt224
        public init() { storage = 0 }
        public init(storage: Sol.UInt224) { self.storage = storage }
    }
}

extension Sol.UFixed224x30: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 224 }
    public static var exponent: Int { 30 }
}

// MARK: - Sol.Fixed224x30

extension Sol {
    public struct Fixed224x30 {
        public var storage: Sol.Int224
        public init() { storage = 0 }
        public init(storage: Sol.Int224) { self.storage = storage }
    }
}

extension Sol.Fixed224x30: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 224 }
    public static var exponent: Int { 30 }
}

