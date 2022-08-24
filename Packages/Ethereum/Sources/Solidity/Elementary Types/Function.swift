//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// MARK: - Sol.Function
extension Sol {
    public struct Function {
        public var address: Sol.Address
        public var selector: Sol.Bytes4
        public init() { address = .init(); selector = .init() }
        public init(address: Sol.Address, selector: Sol.Bytes4) { self.address = address; self.selector = selector }
        public var bytes24Value: Sol.Bytes24 {
            // we need to remove the padding (12 bytes) from the left
            let addressBytes = address.encode()[12..<32]
            assert(addressBytes.count == 20)
            let bytes24 = Sol.Bytes24(storage: addressBytes + selector.storage)
            return bytes24
        }
    }
}

// MARK: - Sol.Bytes<M>

extension Sol.Function: SolAbiEncodable {
    public func encode() -> Data {
        // an address (20 bytes) followed by a function selector (4 bytes). Encoded identical to bytes24
        let result = bytes24Value.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        var bytes24 = Sol.Bytes24(storage: Data())
        try bytes24.decode(from: data, offset: &offset)

        // add padding to 32 so that decoding would work
        let addressBytes = Data(repeating: 0, count: 12) + bytes24.storage[0..<20]
        var addressOffset = 0
        self.address = try Sol.Address(from: addressBytes, offset: &addressOffset)

        let selectorStorage = bytes24.storage[20..<24]
        self.selector = Sol.Bytes4(storage: selectorStorage)
    }

    public func encodePacked() -> Data {
        let result = bytes24Value.encodePacked()
        return result
    }

    public var canonicalName: String {
        "function"
    }
}

extension Sol.Function: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address && lhs.selector == rhs.selector
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(selector)
    }
}
