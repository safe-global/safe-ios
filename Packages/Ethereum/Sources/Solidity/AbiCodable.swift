//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 28.12.21.
//

import Foundation

public protocol AbiEncodable {
    func encode() -> Data
    var abiDescription: Sol.AbiTypeDescription { get }
}

extension Sol {
    public struct AbiTypeDescription: Hashable {
        // needed for function_selector encoding
        public var canonicalName: Swift.String
        // needed for tuple encoding
        public var isDynamic: Swift.Bool
        // needed for tuple encoding
        public var headSize: Swift.Int

        public init(canonicalName: Swift.String, isDynamic: Swift.Bool, headSize: Swift.Int) {
            self.canonicalName = canonicalName
            self.isDynamic = isDynamic
            self.headSize = headSize
        }
    }
}

public protocol AbiDecodable {
    init(from data: Data, offset: inout Int) throws
}

public protocol SolType: AbiEncodable, AbiDecodable {
}


struct AbiDecodingError: Error {
    static let dataInvalid = AbiDecodingError()
    static let outOfBounds = AbiDecodingError()
}

// decoding
//   contract description + data -> created types
        // contract description -> canonical description -> types


//   canonical description + data -> created types
//      parsing of '(' ')' and '[]' and '[k]'
//      parsing of uintM, intM, ufixedMxN, fixedMxN, bytesM
//      and others
