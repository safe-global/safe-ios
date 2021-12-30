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

// signed or unsigned integer
public protocol SolInteger: SolType {}

// TODO: Fixed Point arithmetic? Numeric? Additive Arithmetic?
// ufixed<M>x<N>
public protocol SolUnsignedFixedPointDecimal: SolType {
    static var bitWidth: Int { get }
    static var exponent: Int { get }
    associatedtype Storage: FixedWidthInteger, UnsignedInteger
    var storage: Storage { get set }
    init()
    init(storage: Storage)
}

public protocol SolSignedFixedPointDecimal: SolType {
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
public protocol SolFixedBytes: SolType {
    static var byteCount: Int { get }
    var storage: Data { get set }
    init()
    init(storage: Data)
}


// MARK: - Encoding

extension SolInteger where Self: FixedWidthInteger {
    public func encode() -> Data {
        // uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
        // int<M>: enc(X) is the big-endian two’s complement encoding of X, padded on the higher-order (left) side with 0xff bytes for negative X and with zero-bytes for non-negative X such that the length is 32 bytes.
        let value = bigEndian
        let bytes = stride(from: 0, to: Self.bitWidth, by: 8).map { bitOffset in
            UInt8((value >> bitOffset) & 0xff)
        }

        let result: Data
        let remainderFrom32 = bytes.count % 32

        if remainderFrom32 == 0 {
            result = Data(bytes)
        } else {
            let padding: UInt8 = self < 0 ? 0xff : 0x00
            result = Data(repeating: padding, count: 32 - remainderFrom32) + Data(bytes)
        }
        assert(result.count == 32)
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: String(describing: type(of: self)).lowercased(),
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        // there must be 32 bytes
        guard offset < data.count - 32 else {
            throw AbiDecodingError.outOfBounds
        }
        // uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
        // int<M>: enc(X) is the big-endian two’s complement encoding of X, padded on the higher-order (left) side with 0xff bytes for negative X and with zero-bytes for non-negative X such that the length is 32 bytes.
        let byteCount = Self.bitWidth / 8
        let remainder32 = byteCount % 32
        let paddingLength = remainder32 == 0 ? 0 : (32 - remainder32)

        let significantBytes = data[offset + paddingLength..<offset + 32]
        self = 0
        for byte in significantBytes {
            self = (self << 8) | Self(byte)
        }

        offset += 32
    }
}

extension SolUnsignedFixedPointDecimal where Storage: AbiEncodable & AbiDecodable {
    public func encode() -> Data {
        // ufixed<M>x<N>: enc(X) is enc(X * 10**N) where X * 10**N is interpreted as a uint256
        let result = storage.encode()
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: String(describing: type(of: self)).lowercased(),
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let storage = try Storage(from: data, offset: &offset)
        self.init(storage: storage)
    }
}

extension SolSignedFixedPointDecimal where Storage: AbiEncodable & AbiDecodable {
    public func encode() -> Data {
        // fixed<M>x<N>: enc(X) is enc(X * 10**N) where X * 10**N is interpreted as a int256
        let result = storage.encode()
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: String(describing: type(of: self)).lowercased(),
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let storage = try Storage(from: data, offset: &offset)
        self.init(storage: storage)
    }
}

extension Sol.Address: SolType {
    public func encode() -> Data {
        // address: as in the uint160 case
        let result = storage.encode()
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "address",
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        storage = try Sol.UInt160(from: data, offset: &offset)
    }
}

extension Sol.Bool: SolType {
    public func encode() -> Data {
        // bool: as in the uint8 case, where 1 is used for true and 0 for false
        let value = storage ? Sol.UInt8(1) : Sol.UInt8(0)
        let result = value.encode()
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "bool",
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let value = try Sol.UInt8(from: data, offset: &offset)
        switch value {
        case 0:
            storage = false

        case 1:
            storage = true

        default:
            // which offset from the beginning?
            // what was expected?
            // what got instead?
            throw AbiDecodingError.dataInvalid
        }
    }
}


extension SolFixedBytes {
    public func encode() -> Data {
        // bytes<M>: enc(X) is the sequence of bytes in X padded with trailing zero-bytes to a length of 32 bytes
        let remainderFrom32 = Self.byteCount % 32
        let result: Data
        if remainderFrom32 == 0 {
            result = storage
        } else {
            result = storage + Data(repeating: 0x00, count: 32 - remainderFrom32)
        }
        assert(result.count == 32)
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "bytes\(Self.byteCount)",
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        guard offset < data.count - 32 else {
            throw AbiDecodingError.outOfBounds
        }
        let remainderFrom32 = Self.byteCount % 32
        let paddingLength = remainderFrom32 == 0 ? 0 : (32 - remainderFrom32)
        let storage = data[0..<paddingLength]
        self.init(storage: storage)
        offset += 32
    }
}

extension Sol.Function: SolType {
    public func encode() -> Data {
        let addressBytes = stride(from: 0, to: type(of: address.storage).bitWidth, by: 8).map { bitOffset in
            UInt8((address.storage >> bitOffset) & 0xff)
        }
        assert(addressBytes.count == 20)
        let bytes24 = Sol.Bytes24(storage: addressBytes + selector.storage)
        let result = bytes24.encode()
        return result
    }
    
    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "bytes24",
            isDynamic: false,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let bytes24 = try Sol.Bytes24(from: data, offset: &offset)

        let selector = bytes24.storage[20..<24]
        self.selector = Sol.Bytes4(storage: selector)

        let addressBytes = bytes24.storage[0..<20]
        var addressStorage: Sol.UInt160 = 0
        for byte in addressBytes {
            addressStorage = (addressStorage << 8) | Sol.UInt160(byte)
        }
        address = Sol.Address(storage: addressStorage)
    }
}
