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

    public var canonicalName: String {
        "\(self.elements.first?.canonicalName ?? String(describing: type(of: Element.self)))[]"
    }

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
        let size = try Sol.UInt256(from: data, offset: &offset)
        guard size <= Int.max else {
            throw SolAbiDecodingError.outOfBounds
        }
        let intSize = Int(size)

        guard offset < data.count else {
            throw SolAbiDecodingError.outOfBounds
        }

        var fixedArray = Sol.FixedArray(size: intSize, repeating: Element.init())
        try fixedArray.decode(from: data, offset: &offset)

        elements = fixedArray.elements
    }

    public func encodePacked() -> Data {
        // The encoding of an array is the concatenation of the encoding of its elements with padding.
        let result = elements.map { $0.encode() }.reduce(Data(), +)
        return result
    }
}

extension Sol.Array: Hashable, Equatable where Element: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.elements == rhs.elements
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}
