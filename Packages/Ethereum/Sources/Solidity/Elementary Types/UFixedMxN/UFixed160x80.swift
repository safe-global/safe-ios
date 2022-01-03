// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed160x80

extension Sol {
    public struct UFixed160x80 {
        public var storage: Sol.UInt160
        public init() { storage = 0 }
        public init(storage: Sol.UInt160) { self.storage = storage }
    }
}

extension Sol.UFixed160x80: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 160 }
    public static var exponent: Int { 80 }
}

// MARK: - Sol.Fixed160x80

extension Sol {
    public struct Fixed160x80 {
        public var storage: Sol.Int160
        public init() { storage = 0 }
        public init(storage: Sol.Int160) { self.storage = storage }
    }
}

extension Sol.Fixed160x80: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 160 }
    public static var exponent: Int { 80 }
}

