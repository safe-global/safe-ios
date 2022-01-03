//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    // TODO: Behave the same as Swift Array of Bytes, or the Data
    public struct Bytes {
        public var storage: Data

        public init(storage: Data) { self.storage = storage }
    }
}

extension Sol.Bytes: SolType {
    public var isDynamic: Bool { true }

    public func encode() -> Data {
        /*
         bytes, of length k (which is assumed to be of type uint256):

         enc(X) = enc(k) pad_right(X), i.e. the number of bytes is encoded as a uint256 followed by the actual value of X as a byte sequence, followed by the minimum number of zero-bytes such that len(enc(X)) is a multiple of 32.
         */
        let size = Sol.UInt256(storage.count).encode()
        let remainder32 = storage.count % 32
        let padded = storage +
            (remainder32 == 0 ? Data() : Data(repeating: 0x00, count: 32 - remainder32))
        let result = size + padded
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        var size = Sol.UInt256()
        try size.decode(from: data, offset: &offset)
        guard size < Int.max else {
            throw AbiDecodingError.outOfBounds
        }
        let intSize = Int(size)

        self.storage = data[offset..<offset + intSize]

        let remainder32 = intSize % 32
        let paddingLength = remainder32 == 0 ? 0 : (32 - remainder32)
        offset += intSize + paddingLength
    }
}
