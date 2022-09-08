//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// MARK: - Sol.Address
extension Sol {
    public struct Address {
        public var storage: UInt160
        public init() { storage = 0 }
        public init(storage: UInt160) { self.storage = storage }
    }
}

extension Sol.Address: SolAbiEncodable {
    public func encode() -> Data {
        // address: as in the uint160 case
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
        "address"
    }
}

extension Sol.Address: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

public extension Sol.Address {
    init?(hex: String) {
        var string = hex
        if string.hasPrefix("0x") {
            string.removeFirst(2)
        }
        guard let uint = Sol.UInt160(string, radix: 16) else {
            return nil
        }
        storage = uint
    }

    init(data: Data) throws {
        if data.isEmpty {
            storage = 0
        } else if data.count == 20 {
            let padded = Data(repeating: 0, count: 32 - 20) + data
            storage = try Sol.UInt160(padded)
        } else {
            storage = try Sol.UInt160(data)
        }
    }

    init?(maybeData: Data) {
        try? self.init(data: maybeData)
    }
}

extension Sol.Address: ExpressibleByStringLiteral {
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

extension Sol.Address: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt) {
        self.init(storage: Sol.UInt160(value))
    }
}
