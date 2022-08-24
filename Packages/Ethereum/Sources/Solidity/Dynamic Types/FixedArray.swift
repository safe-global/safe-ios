//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    public struct FixedArray<Element: SolAbiEncodable> {
        public var size: Swift.Int
        public var elements: [Element]

        public init(size: Swift.Int, elements: [Element]) {
            self.size = size
            self.elements = elements
            precondition(elements.count == size)
        }

        public init(size: Swift.Int, repeating: Element) {
            self.size = size
            self.elements = [Element](repeating: repeating, count: size)
        }

        public init() { size = 0; elements = [] }
    }
}

extension Sol.FixedArray: SolAbiEncodable {
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

    public mutating func decode(from data: Data, offset: inout Int) throws {
        precondition(elements.count == size)
        var tuple = Sol.Tuple(elements: elements)
        try tuple.decode(from: data, offset: &offset)
        elements = tuple.elements as! [Element]
    }

    public var isDynamic: Bool {
        elements.first?.isDynamic ?? false
    }

    public var headSize: Int {
        (elements.first?.headSize ?? 32) * elements.count
    }

    public var canonicalName: String {
        "\(self.elements.first?.canonicalName ?? String(describing: Element.self).lowercased())[\(size)]"
    }

    public func encodePacked() -> Data {
        // The encoding of an array is the concatenation of the encoding of its elements with padding.
        let result = elements.map { $0.encode() }.reduce(Data(), +)
        return result
    }
}
