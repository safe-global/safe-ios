//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// TODO: Fixed Point arithmetic? Numeric? Additive Arithmetic?
extension Sol {
    public struct UnsignedFixedPoint<T> where T: FixedWidthInteger & UnsignedInteger {
        public var storage: T
        public var exponent: Swift.Int
        public init() { storage = .init(); exponent = 18 }
        public init(storage: T, exponent: Swift.Int) { self.storage = storage; self.exponent = exponent }
    }
}

extension Sol.UnsignedFixedPoint: SolAbiEncodable where T: SolAbiEncodable {
    public func encode() -> Data {
        let result = storage.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        try self.storage.decode(from: data, offset: &offset)
    }

    public func encodePacked() -> Data {
        let result = storage.encodePacked()
        return result
    }

    public var canonicalName: String {
        "ufixed\(storage.self.bitWidth)x\(exponent)"
    }
}

extension Sol.UnsignedFixedPoint: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.exponent == rhs.exponent && lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(exponent)
        hasher.combine(storage)
    }
}

extension Sol {
    public struct SignedFixedPoint<T> where T: FixedWidthInteger & SignedInteger {
        public var storage: T
        public var exponent: Swift.Int
        public init() { storage = .init(); exponent = 18 }
        public init(storage: T, exponent: Swift.Int) { self.storage = storage; self.exponent = exponent }
    }
}

extension Sol.SignedFixedPoint: SolAbiEncodable where T: SolAbiEncodable {
    public func encode() -> Data {
        let result = storage.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        try self.storage.decode(from: data, offset: &offset)
    }

    public func encodePacked() -> Data {
        let result = storage.encodePacked()
        return result
    }

    public var canonicalName: String {
        "fixed\(storage.self.bitWidth)x\(exponent)"
    }
}

extension Sol.SignedFixedPoint: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.exponent == rhs.exponent && lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(exponent)
        hasher.combine(storage)
    }
}
