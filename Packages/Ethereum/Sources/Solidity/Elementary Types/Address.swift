//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// MARK: - Sol.Address
extension Sol {
    // TODO: init with string
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
}

extension Sol.Address: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}
