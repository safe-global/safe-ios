//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 28.12.21.
//

import Foundation

public protocol SolAbiEncodable {
    var isDynamic: Bool { get }
    var headSize: Int { get }
    var canonicalName: String { get }
    func encode() -> Data
    func encodePacked() -> Data
    mutating func decode(from data: Data, offset: inout Int) throws
    init()
}

public extension SolAbiEncodable {
    var isDynamic: Bool { false }
    var headSize: Int { 32 }

    init(from data: Data, offset: inout Int) throws {
        self.init()
        try self.decode(from: data, offset: &offset)
    }

    init(_ data: Data) throws {
        var offset = 0
        try self.init(from: data, offset: &offset)
    }

    init?(exactly data: Data) {
        try? self.init(data)
    }
}

struct SolAbiDecodingError: Error {
    static let dataInvalid = SolAbiDecodingError(code: -1, message: "Data invalid")
    static let outOfBounds = SolAbiDecodingError(code: -2, message: "Data offset is out of bounds")

    let code: Int
    let message: String
}
