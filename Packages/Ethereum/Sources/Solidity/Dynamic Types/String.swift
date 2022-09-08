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

        public init() { storage = "" }

        public var bytesValue: Sol.Bytes {
            guard let utf8 = storage.data(using: .utf8) else {
                return Sol.Bytes(storage: Data())
            }
            let bytes = Sol.Bytes(storage: utf8)
            return bytes
        }
    }
}

extension Sol.String: SolAbiEncodable {
    public var isDynamic: Bool { true }

    public var canonicalName: String { "string" }
    
    public func encode() -> Data {
        /*
         enc(X) = enc(enc_utf8(X)), i.e. X is UTF-8 encoded and this value is interpreted as of bytes type and encoded further.
         Note that the length used in this subsequent encoding is the number of bytes of the UTF-8 encoded string, not its number of characters.
         */
        let result = bytesValue.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        let bytes = try Sol.Bytes(from: data, offset: &offset)

        guard let storage = String(data: bytes.storage, encoding: .utf8) else {
            throw SolAbiDecodingError.dataInvalid
        }
        self.storage = storage
    }

    public func encodePacked() -> Data {
        let result = bytesValue.encodePacked()
        return result
    }
}

extension Sol.String: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}
