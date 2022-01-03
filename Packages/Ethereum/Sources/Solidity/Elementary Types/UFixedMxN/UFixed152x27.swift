// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed152x27

extension Sol {
    public struct UFixed152x27 {
        public var storage: Sol.UInt152
        public init() { storage = 0 }
        public init(storage: Sol.UInt152) { self.storage = storage }
    }
}

extension Sol.UFixed152x27: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 152 }
    public static var exponent: Int { 27 }
}

// MARK: - Sol.Fixed152x27

extension Sol {
    public struct Fixed152x27 {
        public var storage: Sol.Int152
        public init() { storage = 0 }
        public init(storage: Sol.Int152) { self.storage = storage }
    }
}

extension Sol.Fixed152x27: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 152 }
    public static var exponent: Int { 27 }
}

