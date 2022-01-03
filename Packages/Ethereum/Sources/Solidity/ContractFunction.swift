//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 03.01.22.
//

import Foundation

public protocol SolContractFunction: SolAbiEncodable {
    var name: String { get }
    var parameters: Sol.Tuple { get set }
    var selector: Sol.Bytes4 { get set }

    associatedtype Returns: SolEncodableTuple
}

extension Sol {
    public struct ContractFunction<R: SolEncodableTuple>: SolContractFunction {
        public var selector: Sol.Bytes4
        public var name: Swift.String
        public var parameters: Sol.Tuple

        public typealias Returns = R

        public init() { name = ""; parameters = .init(); selector = .init() }

        public init(name: Swift.String, parameters: Sol.Tuple) {
            self.name = name
            self.parameters = parameters
            self.selector = .init()
            self.selector = derivedSelector
        }

        public init(name: Swift.String, parameters: Sol.Tuple, selector: Sol.Bytes4) {
            self.name = name
            self.parameters = parameters
            self.selector = selector
        }
    }
}

extension SolContractFunction {
    public var canonicalName: String {
        name + parameters.canonicalName
    }

    public var isDynamic: Bool {
        parameters.isDynamic
    }

    public var headSize: Int {
        isDynamic ? 32 : (selector.headSize + parameters.headSize)
    }

    public var derivedSelector: Sol.Bytes4 {
        fatalError()
    }

    public func encode() -> Data {
        /*
         All in all, a call to the function f with parameters a_1, ..., a_n is encoded as

         function_selector(f) enc((a_1, ..., a_n))

         and the return values v_1, ..., v_k of f are encoded as

         enc((v_1, ..., v_k))

         i.e. the values are combined into a tuple and encoded.


         The first four bytes of the call data for a function call specifies the function to be called. It is the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function. The signature is defined as the canonical expression of the basic prototype without data location specifier, i.e. the function name with the parenthesised list of parameter types. Parameter types are split by a single comma - no spaces are used.
         */
        let result = selector.encode() + parameters.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        self.selector = try Sol.Bytes4(from: data, offset: &offset)
        try self.parameters.decode(from: data, offset: &offset)
    }
}

extension SolContractFunction where Self: SolKeyPathTuple {
    public var name: String {
        String(describing: type(of: self))
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
            derivedSelector
        }
        set {
            // do  nothing
        }
    }
}
