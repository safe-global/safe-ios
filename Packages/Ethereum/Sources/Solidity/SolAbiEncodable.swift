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
    func encode() -> Data
    mutating func decode(from data: Data, offset: inout Int) throws
}

public extension SolAbiEncodable {
    var isDynamic: Bool { false }
    var headSize: Int { 32 }
}

struct SolAbiDecodingError: Error {
    static let dataInvalid = SolAbiDecodingError()
    static let outOfBounds = SolAbiDecodingError()
}
