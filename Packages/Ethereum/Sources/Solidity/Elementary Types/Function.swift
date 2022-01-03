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
    }
}

// MARK: - Sol.Bytes<M>

extension Sol.Function: SolAbiEncodable {
    public func encode() -> Data {
        let addressBytes = stride(from: 0, to: type(of: address.storage).bitWidth, by: 8).map { bitOffset in
            UInt8((address.storage >> bitOffset) & 0xff)
        }
        assert(addressBytes.count == 20)
        let bytes24 = Sol.Bytes24(storage: addressBytes + selector.storage)
        let result = bytes24.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        var bytes24 = Sol.Bytes24(storage: Data())
        try bytes24.decode(from: data, offset: &offset)

        let selectorStorage = bytes24.storage[20..<24]
        self.selector = Sol.Bytes4(storage: selectorStorage)

        // add padding to 32 so that decoding would work
        let addressBytes = Data(repeating: 0, count: 12) + bytes24.storage[0..<20]
        var uint160 = Sol.UInt160()
        var addressOffset = 0
        try uint160.decode(from: addressBytes, offset: &addressOffset)
        self.address = Sol.Address(storage: uint160)
    }
}
