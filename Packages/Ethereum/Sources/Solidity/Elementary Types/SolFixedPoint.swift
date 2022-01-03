//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// TODO: Fixed Point arithmetic? Numeric? Additive Arithmetic?
// ufixed<M>x<N>
public protocol SolUnsignedFixedPointDecimal: SolAbiEncodable {
    static var bitWidth: Int { get }
    static var exponent: Int { get }
    associatedtype Storage: FixedWidthInteger, UnsignedInteger
    var storage: Storage { get set }
    init()
    init(storage: Storage)
}

public protocol SolSignedFixedPointDecimal: SolAbiEncodable {
    static var bitWidth: Int { get }
    static var exponent: Int { get }
    associatedtype Storage: FixedWidthInteger, SignedInteger
    var storage: Storage { get set }
    init()
    init(storage: Storage)
}

extension SolUnsignedFixedPointDecimal where Storage: SolAbiEncodable {
    public func encode() -> Data {
        // ufixed<M>x<N>: enc(X) is enc(X * 10**N) where X * 10**N is interpreted as a uint256
        let result = storage.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        try self.storage.decode(from: data, offset: &offset)
    }
}

extension SolSignedFixedPointDecimal where Storage: SolAbiEncodable {
    public func encode() -> Data {
        // fixed<M>x<N>: enc(X) is enc(X * 10**N) where X * 10**N is interpreted as a int256
        let result = storage.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        try self.storage.decode(from: data, offset: &offset)
    }
}
