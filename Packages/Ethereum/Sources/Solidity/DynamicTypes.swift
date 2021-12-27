//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 27.12.21.
//

import Foundation

extension Sol {
    // variable-length array of any element
    public struct Array<Element: SolType> {
        public var elements: [Element]
        public init() { elements = [] }
        public init(elements: [Element]) { self.elements = elements }
    }

    public struct Bytes {
        public var storage: Data
        public init() { storage = Data() }
        public init(storage: Data) { self.storage = storage }
    }

    public struct String {
        public var storage: Swift.String
        public init() { storage = Swift.String() }
        public init(storage: Swift.String) { self.storage = storage }
    }
}

// since Tuples are code-specific, we define a protocol that will add required functionality
// when added to a struct
public protocol SolTuple {
    // only used in the isStatic default implementation.
    // Soltype.type
    static var types: [Any.Type] { get }
}

// similar to Tuples, fixed arrays are code-specific, i.e. instead of pre-defining some specific types
// we define this protocol that implements the required functionality, and the user-defined
// fixed array type can conform to it.
public protocol SolFixedArray {
    static var size: Int { get }
    associatedtype Element: SolType
    var elements: [Element] { get set }
    init()
    init(elements: [Element])
}
