//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 27.12.21.
//

import Foundation

// MARK: - Sol.UInt, Sol.Int

extension Sol {
    typealias UInt = UInt256
    typealias Int = Int256
}

// MARK: - Sol.UFixed, Sol.Fixed

extension Sol {
    typealias UFixed = UFixed128x18
    typealias Fixed = Fixed128x18
}


// TODO: Fixed Point arithmetic? Numeric? Additive Arithmetic?
// ufixed<M>x<N>
public protocol SolUnsignedFixedPointDecimal {
    static var bitWidth: Int { get }
    static var exponent: Int { get }
    associatedtype Storage: FixedWidthInteger, UnsignedInteger
    var storage: Storage { get set }
    init()
    init(storage: Storage)
}

public protocol SolSignedFixedPointDecimal {
    static var bitWidth: Int { get }
    static var exponent: Int { get }
    associatedtype Storage: FixedWidthInteger, SignedInteger
    var storage: Storage { get set }
    init()
    init(storage: Storage)
}

// MARK: - Sol.Address
extension Sol {
    // TODO: init with string
    public struct Address {
        public var storage: UInt160
        public init() { storage = 0 }
        public init(storage: UInt160) { self.storage = storage }
    }
}

// MARK: - Sol.Bool
extension Sol {
    // TODO: Behave the same as Swift Bool
    public struct Bool {
        public var storage: Swift.Bool
        public init() { storage = false }
        public init(storage: Swift.Bool) { self.storage = storage }
    }
}

// MARK: - Sol.Function
extension Sol {
    public struct Function {
        public var address: Sol.Address
        public var selector: Sol.Bytes4
        public init() { address = .init(); selector = .init() }
        public init(address: Sol.Address, selector: Sol.Bytes4) { self.address = address; self.selector = selector }
    }
}

// MARK: - Sol.Bytes<M>

// TODO: Behave the same way as Swift Array / Data of bytes
public protocol SolFixedBytes {
    static var byteCount: Int { get }
    var storage: Data { get set }
    init()
    init(storage: Data)
}

