// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed72x66

extension Sol {
    public struct UFixed72x66 {
        public var storage: Sol.UInt72
        public init() { storage = 0 }
        public init(storage: Sol.UInt72) { self.storage = storage }
    }
}

extension Sol.UFixed72x66: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 72 }
    public static var exponent: Int { 66 }
}

// MARK: - Sol.Fixed72x66

extension Sol {
    public struct Fixed72x66 {
        public var storage: Sol.Int72
        public init() { storage = 0 }
        public init(storage: Sol.Int72) { self.storage = storage }
    }
}

extension Sol.Fixed72x66: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 72 }
    public static var exponent: Int { 66 }
}

