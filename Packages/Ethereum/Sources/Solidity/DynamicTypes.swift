//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 27.12.21.
//

import Foundation

extension Sol {
    // TODO: behave the same as Swift Array
    // variable-length array of any element
    public struct Array<Element: SolType> {
        public var elements: [Element]
        public init() { elements = [] }
        public init(elements: [Element]) { self.elements = elements }
    }

    // TODO: Behave the same as Swift Array of Bytes, or the Data
    public struct Bytes {
        public var storage: Data
        public init() { storage = Data() }
        public init(storage: Data) { self.storage = storage }
    }

    // TODO: Behave the same way as Swift String?
    public struct String {
        public var storage: Swift.String
        public init() { storage = Swift.String() }
        public init(storage: Swift.String) { self.storage = storage }
    }

    public struct Tuple {
        public var elements: [SolType]
        public init() { elements = [] }
        public init(elements: [SolType]) { self.elements = elements }
    }

    public struct FixedArray<Element: SolType> {
        public var size: Swift.Int
        public var elements: [SolType]

        public init() { self.init(size: 0, elements: []) }

        public init(size: Swift.Int, elements: [SolType]) {
            self.elements = elements
            self.size = size
            precondition(elements.count == size)
        }
    }
}


extension Sol {
    struct AbiTypeDescription {
        // needed for function_selector encoding
        var canonicalName: Swift.String
        // needed for tuple encoding
        var isDynamic: Swift.Bool
        // needed for tuple encoding
        var headSize: Swift.Int
    }
}


// TODO: Behave the same way as Swift Array
// similar to Tuples, fixed arrays are code-specific, i.e. instead of pre-defining some specific types
// we define this protocol that implements the required functionality, and the user-defined
// fixed array type can conform to it.
//public protocol SolFixedArray {
//    static var size: Int { get }
//    associatedtype Element: SolType
//    var elements: [Element] { get set }
//    init()
//    init(elements: [Element])
//}


// only used in the isStatic default implementation.
// Soltype.type
//    static var types: [Any.Type] { get }

//    var elements: [SolType] { get set }
//}


// TODO: Behave the same way as Swift Array
// since Tuples are code-specific, we define a protocol that will add required functionality
// when added to a struct
public protocol SolTuple: SolType {

}

// this is for custom tuples that ... but we can convert actually
extension SolTuple {
    public func encode() -> Data {
        /*
         Definition: The following types are called “dynamic”:

         bytes
         string
         T[] for any T
         T[k] for any dynamic T and any k >= 0
         (T1,...,Tk) if Ti is dynamic for some 1 <= i <= k
         All other types are called “static”.

         Definition: len(a) is the number of bytes in a binary string a. The type of len(a) is assumed to be uint256.

         We define enc, the actual encoding, as a mapping of values of the ABI types to binary strings such that len(enc(X)) depends on the value of X if and only if the type of X is dynamic.

         For any ABI value X, we recursively define enc(X), depending on the type of X being

         (T1,...,Tk) for k >= 0 and any types T1, …, Tk

         enc(X) = head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(k))

         where X = (X(1), ..., X(k)) and head and tail are defined for Ti as follows:

         if Ti is static:

         head(X(i)) = enc(X(i)) and tail(X(i)) = "" (the empty string)
         otherwise, i.e. if Ti is dynamic:

         head(X(i)) = enc(len( head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(i-1)) )) tail(X(i)) = enc(X(i))

         Note that in the dynamic case, head(X(i)) is well-defined since the lengths of the head parts only depend on the types and not the values. The value of head(X(i)) is the offset of the beginning of tail(X(i)) relative to the start of enc(X).
         */

        // mirror describes an instance of a type
        // from it we will get the actual types of the tuple.
        let mirror = Mirror(reflecting: self)
        let elements = mirror.children.compactMap { $0.value as? AbiEncodable }

        let sizeOfHeads = elements
            .map { type(of: $0).headSize($0) }
            .reduce(0, +)

        var (heads, tails) = (Data(), Data())
        for element in elements {
            let head: Data, tail: Data
            // we pass the element as a hint because Swift can make reflection only
            // of an instance, and not of a type. This means that for tuple types
            // we can only get types of elements when they are in the actual tuple.
            if type(of: element).isDynamic(element) {
                let offset: Sol.UInt256 = Sol.UInt256(sizeOfHeads + tails.count)
                head = offset.encode()
                tail = element.encode()
            } else {
                head = element.encode()
                tail = Data()
            }
            heads.append(head)
            tails.append(tail)
        }
        let result = heads + tails
        return result
    }

    public static func isDynamic(_ hint: AbiEncodable?) -> Bool {
        // true iff there exists a child element that is dynamic.
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let element = child.value as? AbiEncodable,
               type(of: element).isDynamic(element) {
                return true
            }
        }
        return false
    }

    public static func headSize(_ hint: AbiEncodable?) -> Int {
        if isDynamic(hint) {
            return 32
        }
        let mirror = Mirror(reflecting: self)
        let result = mirror.children
            .compactMap { $0.value as? AbiEncodable }
            .map { type(of: $0).headSize($0) }
            .reduce(0, +)
        return result
    }

    public var canonicalTypeName: String {
        let mirror = Mirror(reflecting: self)
        let elementTypes = mirror.children
            .compactMap { $0.value as? SolType }
            .map(\.canonicalTypeName)
        return "(\(elementTypes.joined(separator: ",")))"
    }
}

extension Sol.Tuple: SolTuple, CustomReflectable {
    public var customMirror: Mirror {
        elements.customMirror
    }
}

/*
 Definition: The following types are called “dynamic”:

 bytes
 string
 T[] for any T
 T[k] for any dynamic T and any k >= 0
 (T1,...,Tk) if Ti is dynamic for some 1 <= i <= k
 All other types are called “static”.
*/

extension Sol.Bytes: SolType {
    public func encode() -> Data {
        /*
         bytes, of length k (which is assumed to be of type uint256):

         enc(X) = enc(k) pad_right(X), i.e. the number of bytes is encoded as a uint256 followed by the actual value of X as a byte sequence, followed by the minimum number of zero-bytes such that len(enc(X)) is a multiple of 32.
         */
        let size = Sol.UInt256(storage.count).encode()
        let remainder32 = storage.count % 32
        let padded = storage +
            (remainder32 == 0 ? Data() : Data(repeating: 0x00, count: 32 - remainder32))
        let result = size + padded
        return result
    }

    public static func isDynamic(_ hint: AbiEncodable?) -> Bool { true }

    public var canonicalTypeName: String {
        "bytes"
    }
}

extension Sol.String: SolType {
    public func encode() -> Data {
        /*
         enc(X) = enc(enc_utf8(X)), i.e. X is UTF-8 encoded and this value is interpreted as of bytes type and encoded further. Note that the length used in this subsequent encoding is the number of bytes of the UTF-8 encoded string, not its number of characters.
         */
        guard let utf8 = storage.data(using: .utf8) else {
            return Data()
        }
        let bytes = Sol.Bytes(storage: utf8)
        let result = bytes.encode()
        return result
    }

    public static func isDynamic(_ hint: AbiEncodable?) -> Bool { true }

    public var canonicalTypeName: String {
        "string"
    }
}

extension Sol.Array: SolType {
    public func encode() -> Data {
        /*
         T[] where X has k elements (k is assumed to be of type uint256):

         enc(X) = enc(k) enc([X[0], ..., X[k-1]])

         i.e. it is encoded as if it were an array of static size k, prefixed with the number of elements.
         */
        let size = Sol.UInt256(self.elements.count).encode()
        let elements = Sol.Tuple(elements: self.elements).encode()
        let result = size + elements
        return result
    }

    public static func isDynamic(_ hint: AbiEncodable?) -> Bool { true }

    public var canonicalTypeName: String {
        "[]"
    }
}

extension Sol.FixedArray: SolType {
    // Note: for the fixed array with Element == Tuple we can't
    // guarantee during compile time that every element has the same type, i.e.
    // that each element is the same tuple.

    // so we'll make a check during encoding process.

    public static func isDynamic(_ hint: AbiEncodable?) -> Bool {
        let array = hint as! Self
        let result = Element.isDynamic(array.elements.first)
        return result
    }

    public static func headSize(_ hint: AbiEncodable?) -> Int {
        if isDynamic(hint) {
            return 32
        }
        let array = hint as! Self
        let result = array.size * Element.headSize(array.elements.first)
        return result
    }

    public func encode() -> Data {
        /*
         T[k] for any T and k:

         enc(X) = enc((X[0], ..., X[k-1]))

         i.e. it is encoded as if it were a tuple with k elements of the same type.
         */
        let tuple = Sol.Tuple(elements: self.elements)
        let result = tuple.encode()
        return result
    }
}

