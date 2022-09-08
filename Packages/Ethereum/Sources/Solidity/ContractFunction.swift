//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 03.01.22.
//

import Foundation
import CryptoSwift

public protocol SolContractFunction: SolAbiEncodable {
    var selector: Sol.Bytes4 { get set }
    var parameters: Sol.Tuple { get set }

    associatedtype Returns: SolEncodableTuple
}

extension Sol {
    public struct ContractFunction<R: SolEncodableTuple>: SolContractFunction {
        public var selector: Sol.Bytes4
        public var parameters: Sol.Tuple

        public var canonicalName: Swift.String {
            let name = selector.storage.map({ Swift.String($0, radix: 16) }).joined()
            let result = name + parameters.canonicalName
            return result
        }

        public typealias Returns = R

        public init() { parameters = .init(); selector = .init() }

        public init(selector: Sol.Bytes4, parameters: Sol.Tuple) {
            self.parameters = parameters
            self.selector = selector
        }
    }
}

extension SolContractFunction {
    public func encode() -> Data {
        /*
         All in all, a call to the function f with parameters a_1, ..., a_n is encoded as

         function_selector(f) enc((a_1, ..., a_n))

         and the return values v_1, ..., v_k of f are encoded as

         enc((v_1, ..., v_k))

         i.e. the values are combined into a tuple and encoded.


         The first four bytes of the call data for a function call specifies the function to be called. It is the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function. The signature is defined as the canonical expression of the basic prototype without data location specifier, i.e. the function name with the parenthesised list of parameter types. Parameter types are split by a single comma - no spaces are used.
         */
        let selector = selector.encode()[0..<4]
        let result = selector + parameters.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        guard offset < data.count - 4 + 1 else {
            throw SolAbiDecodingError.outOfBounds
        }
        let selectorData = data[offset..<offset + 4] + Data(repeating: 0x00, count: 32 - 4)
        var selectorOffset = 0
        self.selector = try Sol.Bytes4(from: selectorData, offset: &selectorOffset)
        offset += 4

        try self.parameters.decode(from: data, offset: &offset)
    }

    public func encodePacked() -> Data {
        // Since packed encoding is not used when calling functions, there is no special support for
        // prepending a function selector.
        let result = parameters.encodePacked()
        return result
    }
}

extension SolContractFunction where Self: SolKeyPathTuple {
    public var canonicalName: String {
        String(describing: type(of: self)) + parameters.canonicalName
    }

    public var parameters: Sol.Tuple {
        get {
            Sol.Tuple(elements: self.elements)
        }
        set {
            self.elements = newValue.elements
        }
    }

    public var selector: Sol.Bytes4 {
        get {
            // keccak256(canonicalName)[0..<4]
            let preimage = canonicalName
            let hashValue = SHA3(variant: .keccak256).calculate(for: preimage.bytes)
            precondition(hashValue.count == 256 / 8)
            let result = Sol.Bytes4(storage: Data(hashValue[0..<4]))
            return result
        }
        set {
            // do  nothing
        }
    }
}
