//
//  DefaultSerializer.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension JsonRpc2 {
    public struct DefaultSerializer: JsonRpc2ClientSerializer {
        public init() {}

        public func toJson<T: Encodable>(value: T) throws -> Data {
            let encoder = JSONEncoder()
            let data = try encoder.encode(value)
            return data
        }

        public func fromJson<T: Decodable>(data: Data) throws -> T {
            let decoder = JSONDecoder()
            let value = try decoder.decode(T.self, from: data)
            return value
        }
    }
}
