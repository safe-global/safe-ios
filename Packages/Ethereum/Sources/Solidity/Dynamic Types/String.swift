//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    // TODO: Behave the same way as Swift String?
    public struct String {
        public var storage: Swift.String

        public init(storage: Swift.String) { self.storage = storage }
    }
}

extension Sol.String: SolType {
    public func encode() -> Data {
        /*
         enc(X) = enc(enc_utf8(X)), i.e. X is UTF-8 encoded and this value is interpreted as of bytes type and encoded further. Note that the length used in this subsequent encoding is the number of bytes of the UTF-8 encoded string, not its number of characters.
         */
        guard let utf8 = storage.data(using: .utf8) else {
            return Data()
        }
        let bytes = Sol.Bytes(storage: utf8)
        let result = bytes.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        var bytes = Sol.Bytes(storage: Data())
        try bytes.decode(from: data, offset: &offset)
        guard let storage = String(data: bytes.storage, encoding: .utf8) else {
            throw AbiDecodingError.dataInvalid
        }
        self.storage = storage
    }
}
