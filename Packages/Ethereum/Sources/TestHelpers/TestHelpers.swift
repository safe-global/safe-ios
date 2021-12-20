//
//  Helper.swift
//  JsonRpc2Tests
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? {
        self
    }

    public var localizedDescription: String {
        self
    }
}

public func decode<T: Decodable>(from str: String) throws -> T {
    guard let data = str.data(using: .utf8) else {
        throw "Can't encode string to utf8 data"
    }
    let decoder = JSONDecoder()
    let element = try decoder.decode(T.self, from: data)
    return element
}

public func encode<T: Encodable>(value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = try encoder.encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
        throw "Can't decode json data to utf8 string"
    }
    return string
}
