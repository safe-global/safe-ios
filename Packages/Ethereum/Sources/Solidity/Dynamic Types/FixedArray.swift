//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    public struct FixedArray<Element: AbiEncodable> {
        public var size: Swift.Int
        public var elements: [Element]

        public init(size: Swift.Int, elements: [Element]) {
            self.size = size
            self.elements = elements
            precondition(elements.count == size)
        }
    }
}

extension Sol.FixedArray: AbiEncodable {
    public func encode() -> Data {
        /*
         T[k] for any T and k:

         enc(X) = enc((X[0], ..., X[k-1]))

         i.e. it is encoded as if it were a tuple with k elements of the same type.
         */
        let tuple = Sol.Tuple(elements: elements)
        let result = tuple.encode()
        return result
    }

    public var isDynamic: Bool {
        elements.first?.isDynamic ?? false
    }

    public var headSize: Int {
        (elements.first?.headSize ?? 32) * elements.count
    }

    // I must have an element and a size.
    public mutating func decode(from data: Data, offset: inout Int) throws {
        precondition(!elements.isEmpty)
        var tuple = Sol.Tuple(elements: [AbiEncodable](repeating: elements[0], count: size))
        try tuple.decode(from: data, offset: &offset)
        elements = tuple.elements as! [Element]
    }
}
