//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// TODO: Behave the same way as Swift Array / Data of bytes
public protocol SolFixedBytes: SolAbiEncodable {
    static var byteCount: Int { get }
    var storage: Data { get set }
    init()
    init(storage: Data)
}


// MARK: - Encoding

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

    public mutating func decode(from data: Data, offset: inout Int) throws {
        guard offset < data.count - 32 else {
            throw SolAbiDecodingError.outOfBounds
        }
        let remainderFrom32 = Self.byteCount % 32
        let paddingLength = remainderFrom32 == 0 ? 0 : (32 - remainderFrom32)
        self.storage = data[0..<paddingLength]

        offset += 32
    }
}
