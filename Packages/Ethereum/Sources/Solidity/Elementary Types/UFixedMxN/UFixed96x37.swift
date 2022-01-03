// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed96x37

extension Sol {
    public struct UFixed96x37 {
        public var storage: Sol.UInt96
        public init() { storage = 0 }
        public init(storage: Sol.UInt96) { self.storage = storage }
    }
}

extension Sol.UFixed96x37: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 96 }
    public static var exponent: Int { 37 }
}

// MARK: - Sol.Fixed96x37

extension Sol {
    public struct Fixed96x37 {
        public var storage: Sol.Int96
        public init() { storage = 0 }
        public init(storage: Sol.Int96) { self.storage = storage }
    }
}

extension Sol.Fixed96x37: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 96 }
    public static var exponent: Int { 37 }
}

