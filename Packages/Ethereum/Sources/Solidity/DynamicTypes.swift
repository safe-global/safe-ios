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
    public struct Array<Element: AbiEncodable & AbiDecodable> {
        public var elementAbiType: AbiTypeDescription
        public var elements: [Element]

        public init(elementAbiType: Sol.AbiTypeDescription, elements: [Element]) {
            self.elementAbiType = elementAbiType
            self.elements = elements

            let derivedAbiTypes = elements.map(\.abiDescription)
            precondition(derivedAbiTypes.allSatisfy { $0 == elementAbiType })
        }
    }

    // TODO: Behave the same as Swift Array of Bytes, or the Data
    public struct Bytes {
        public var storage: Data

        public init(storage: Data) { self.storage = storage }
    }

    // TODO: Behave the same way as Swift String?
    public struct String {
        public var storage: Swift.String

        public init(storage: Swift.String) { self.storage = storage }
    }

    public struct Tuple {
        public typealias Element = AbiEncodable & AbiDecodable
        public var elementAbiTypes: [Sol.AbiTypeDescription]
        public var elements: [Element]

        public init(elements: [Element]) {
            self.elementAbiTypes = elements.map(\.abiDescription)
            self.elements = elements
        }

        public init(elementAbiTypes: [Sol.AbiTypeDescription], elements: [Element]) {
            self.elementAbiTypes = elementAbiTypes
            self.elements = elements

            let derivedAbiTypes = elements.map(\.abiDescription)
            precondition(elementAbiTypes == derivedAbiTypes)
        }
    }

    public struct FixedArray<Element: AbiEncodable & AbiDecodable> {
        public var size: Swift.Int
        public var elementAbiType: AbiTypeDescription
        public var elements: [Element]

        public init(size: Swift.Int, elementAbiType: Sol.AbiTypeDescription, elements: [Element]) {
            self.size = size
            self.elementAbiType = elementAbiType
            self.elements = elements

            precondition(elements.count == size)

            let derivedAbiTypes = elements.map(\.abiDescription)
            precondition(derivedAbiTypes.allSatisfy { $0 == elementAbiType })
        }
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
public protocol SolTuple: AbiEncodable {
    // requires that the mirorr's AbiTypes are equal to this value
    var elementAbiTypes: [Sol.AbiTypeDescription] { get }
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


        let elements = mirrorElements
        let abiTypes = elementAbiTypes

        precondition(elements.count == abiTypes.count)

        let sizeOfHeads = abiTypes
            .map(\.headSize)
            .reduce(0, +)

        var (heads, tails) = (Data(), Data())
        for (element, abiType) in zip(elements, abiTypes) {
            let head: Data, tail: Data
            if abiType.isDynamic {
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

    internal var mirrorElements: [AbiEncodable] {
        let mirror = Mirror(reflecting: self)
        let elements = mirror.children.compactMap { $0.value as? AbiEncodable }
        return elements
    }

    public var elementAbiTypes: [Sol.AbiTypeDescription] {
        mirrorElements.map(\.abiDescription)
    }

    public var abiDescription: Sol.AbiTypeDescription {
        let isDynamic = elementAbiTypes.contains(where: \.isDynamic)
        let result = Sol.AbiTypeDescription(
            canonicalName: "(\(elementAbiTypes.map(\.canonicalName).joined(separator: ",")))",
            isDynamic: isDynamic,
            headSize: isDynamic ? 32 : elementAbiTypes.map(\.headSize).reduce(0, +)
        )
        return result
    }

    static func elements(from data: Data, offset: inout Int, abiTypes: [(AbiDecodable.Type, Bool)]) throws -> [AbiDecodable] {
        var result: [AbiDecodable] = []
        for (elementType, isDynamic) in abiTypes {
            if isDynamic {
                let tailOffset = try Sol.UInt256(from: data, offset: &offset)
                guard tailOffset < Int.max else {
                    throw AbiDecodingError.outOfBounds
                }
                var intTailOffset = Int(tailOffset)
                let tail = try elementType.init(from: data, offset: &intTailOffset)
                result.append(tail)
            } else {
                let head = try elementType.init(from: data, offset: &offset)
                result.append(head)
            }
        }
        return result
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

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "bytes",
            isDynamic: true,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let size = try Sol.UInt256(from: data, offset: &offset)
        guard size < Int.max else {
            throw AbiDecodingError.outOfBounds
        }
        let intSize = Int(size)
        let storage = data[offset..<offset + intSize]
        self.init(storage: storage)
        let remainder32 = intSize % 32
        let paddingLength = remainder32 == 0 ? 0 : (32 - remainder32)
        offset += intSize + paddingLength
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

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: "string",
            isDynamic: true,
            headSize: 32
        )
    }

    public init(from data: Data, offset: inout Int) throws {
        let bytes = try Sol.Bytes(from: data, offset: &offset)
        guard let storage = String(data: bytes.storage, encoding: .utf8) else {
            throw AbiDecodingError.dataInvalid
        }
        self.init(storage: storage)
    }
}

extension Sol.Array: AbiEncodable {
    public func encode() -> Data {
        /*
         T[] where X has k elements (k is assumed to be of type uint256):

         enc(X) = enc(k) enc([X[0], ..., X[k-1]])

         i.e. it is encoded as if it were an array of static size k, prefixed with the number of elements.
         */
        let size = Sol.UInt256(self.elements.count).encode()
        let fixedArray = Sol.FixedArray(size: self.elements.count,
                                        elementAbiType: elementAbiType,
                                        elements: self.elements)

        let elements = fixedArray.encode()
        let result = size + elements
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: elementAbiType.canonicalName + "[]",
            isDynamic: true,
            headSize: 32
        )
    }

    public static func decode(from data: Data, offset: inout Int, isDynamic: Bool) throws -> [Element] {
        let size = try Sol.UInt256(from: data, offset: &offset)
        guard size <= Int.max else {
            throw AbiDecodingError.outOfBounds
        }
        let intSize = Int(size)
        let elements = try Sol.FixedArray<Element>.decode(from: data, offset: &offset, size: intSize, isDynamic: isDynamic)
        return elements
    }
}

extension Sol.FixedArray: AbiEncodable {
    // requires that abi description correctly describes the element.
    public func encode() -> Data {
        /*
         T[k] for any T and k:

         enc(X) = enc((X[0], ..., X[k-1]))

         i.e. it is encoded as if it were a tuple with k elements of the same type.
         */
        let tuple = Sol.Tuple(
            elementAbiTypes: [Sol.AbiTypeDescription](repeating: elementAbiType, count: elements.count),
            elements: elements
        )
        let result = tuple.encode()
        return result
    }

    public var abiDescription: Sol.AbiTypeDescription {
        Sol.AbiTypeDescription(
            canonicalName: elementAbiType.canonicalName + "[\(size)]",
            isDynamic: elementAbiType.isDynamic,
            headSize: elementAbiType.isDynamic ? 32 : (size * elementAbiType.headSize)
        )
    }

    static func decode(from data: Data, offset: inout Int, size: Int, isDynamic: Bool) throws -> [Element] {
        let elements = try Sol.Tuple.elements(from: data, offset: &offset, abiTypes: [(AbiDecodable.Type, Bool)](repeating: (Element.self, isDynamic), count: size))
        return elements as! [Element]
    }
}
