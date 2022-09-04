//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// TODO: Behave the same way as Swift Array / Data of bytes
public protocol SolFixedBytes: SolAbiEncodable, Hashable, ExpressibleByStringLiteral {
    static var byteCount: Int { get }
    var storage: Data { get set }
    init()
    init(storage: Data)
    init?(hex: String)
}

// MARK: - Encoding

extension SolFixedBytes {
    public init() {
        self.init(storage: Data(repeating: 0x00, count: Self.byteCount))
    }

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

    public mutating func decode(from data: Data, offset: inout Int) throws {
        guard offset < data.count - 32 + 1 else {
            throw SolAbiDecodingError.outOfBounds
        }
        self.storage = data[offset..<offset + Self.byteCount]

        offset += 32
    }

    public func encodePacked() -> Data {
        // bytes<M>: enc(X) is the sequence of bytes
        storage
    }

    public var canonicalName: String {
        "bytes\(Self.byteCount)"
    }
}

extension SolFixedBytes {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

extension SolFixedBytes {
    public init?(hex: String) {
        let data = Data(hex: hex)
        if data.count != Self.byteCount {
            return nil
        }
        self.init(storage: data)
    }

    public init(stringLiteral value: String) {
        self.init(hex: value)!
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(hex: value)!
    }

    public init(unicodeScalarLiteral value: String) {
        self.init(hex: value)!
    }
}
