// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed152x16

extension Sol {
    public struct UFixed152x16 {
        public var storage: Sol.UInt152
        public init() { storage = 0 }
        public init(storage: Sol.UInt152) { self.storage = storage }
    }
}

extension Sol.UFixed152x16: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 152 }
    public static var exponent: Int { 16 }
}

// MARK: - Sol.Fixed152x16

extension Sol {
    public struct Fixed152x16 {
        public var storage: Sol.Int152
        public init() { storage = 0 }
        public init(storage: Sol.Int152) { self.storage = storage }
    }
}

extension Sol.Fixed152x16: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 152 }
    public static var exponent: Int { 16 }
}

