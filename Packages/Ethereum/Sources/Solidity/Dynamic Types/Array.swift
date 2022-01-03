//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    // TODO: behave the same as Swift Array
    // variable-length array of any element
    public struct Array<Element: SolAbiEncodable> {
        public var elements: [Element]

        public init(elements: [Element]) {
            self.elements = elements
        }

        public init() { self.elements = [] }
    }

}

extension Sol.Array: SolAbiEncodable {
    public var isDynamic: Bool { true }

    public func encode() -> Data {
        /*
         T[] where X has k elements (k is assumed to be of type uint256):

         enc(X) = enc(k) enc([X[0], ..., X[k-1]])

         i.e. it is encoded as if it were an array of static size k, prefixed with the number of elements.
         */
        let size = Sol.UInt256(self.elements.count).encode()
        let fixedArray = Sol.FixedArray(size: self.elements.count, elements: self.elements)
        let elements = fixedArray.encode()
        let result = size + elements
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        precondition(!elements.isEmpty)
        let size = try Sol.UInt256(from: data, offset: &offset)
        guard size <= Int.max else {
            throw SolAbiDecodingError.outOfBounds
        }
        let intSize = Int(size)

        var fixedArray = Sol.FixedArray(size: intSize, elements: elements)
        try fixedArray.decode(from: data, offset: &offset)
    }
}

