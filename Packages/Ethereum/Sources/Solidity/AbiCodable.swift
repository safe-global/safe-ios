//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 28.12.21.
//

import Foundation

public protocol AbiEncodable {
    func encode() -> Data
    static func isDynamic(_ hint: AbiEncodable?) -> Bool
    static func headSize(_ hint: AbiEncodable?) -> Int
}

extension AbiEncodable {
    public static func isDynamic(_ hint: AbiEncodable?) -> Bool {
        false
    }

    public static func headSize(_ hint: AbiEncodable?) -> Int { 32 }
}

public protocol AbiDecodable {
    init(from decoder: AbiDecoder) throws
}

public struct AbiEncoder {
    public init() {}

    public func encode(_ value: Data) {

    }
}

public struct AbiDecoder {
    public init() {}
}

typealias AbiCodable = AbiEncodable & AbiDecodable
