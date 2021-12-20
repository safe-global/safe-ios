//
//  JsonRpc2ClientSerializer.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import Foundation

// Responsible for converting something Codable to and from json data
public protocol JsonRpc2ClientSerializer {
    func toJson<T: Encodable>(value: T) throws -> Data
    func fromJson<T: Decodable>(data: Data) throws -> T
}
