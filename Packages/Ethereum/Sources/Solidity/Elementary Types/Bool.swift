//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// MARK: - Sol.Bool
extension Sol {
    // TODO: Behave the same as Swift Bool
    public struct Bool {
        public var storage: Swift.Bool
        public init() { storage = false }
        public init(storage: Swift.Bool) { self.storage = storage }
    }
}

extension Sol.Bool: SolAbiEncodable {
    public func encode() -> Data {
        // bool: as in the uint8 case, where 1 is used for true and 0 for false
        let value = storage ? Sol.UInt8(1) : Sol.UInt8(0)
        let result = value.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        var value = Sol.UInt8()
        try value.decode(from: data, offset: &offset)

        switch value {
        case 0:
            storage = false

        case 1:
            storage = true

        default:
            // which offset from the beginning?
            // what was expected?
            // what got instead?
            throw SolAbiDecodingError.dataInvalid
        }
    }
}
