// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed104x30

extension Sol {
    public struct UFixed104x30 {
        public var storage: Sol.UInt104
        public init() { storage = 0 }
        public init(storage: Sol.UInt104) { self.storage = storage }
    }
}

extension Sol.UFixed104x30: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { 104 }
    public static var exponent: Int { 30 }
}

// MARK: - Sol.Fixed104x30

extension Sol {
    public struct Fixed104x30 {
        public var storage: Sol.Int104
        public init() { storage = 0 }
        public init(storage: Sol.Int104) { self.storage = storage }
    }
}

extension Sol.Fixed104x30: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { 104 }
    public static var exponent: Int { 30 }
}

