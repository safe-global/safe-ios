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
}

struct SolAbiDecodingError: Error {
    static let dataInvalid = SolAbiDecodingError(code: -1)
    static let outOfBounds = SolAbiDecodingError(code: -2)

    let code: Int
}
