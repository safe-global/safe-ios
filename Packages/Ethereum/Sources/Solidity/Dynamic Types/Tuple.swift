//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

extension Sol {
    public struct Tuple: SolEncodableTuple {
        public var elements: [SolAbiEncodable]

        public init(elements: [SolAbiEncodable]) {
            self.elements = elements
        }

        public init() { elements = [] }
    }
}

// TODO: Behave the same way as Swift Array
public protocol SolEncodableTuple: SolAbiEncodable {
    var elements: [SolAbiEncodable] { get set }
}

// this is for custom tuples that ... but we can convert actually
extension SolEncodableTuple {

    public var isDynamic: Bool {
        elements.contains(where: \.isDynamic)
    }

    public var headSize: Int {
        isDynamic ? 32 : elements.map(\.headSize).reduce(0, +)
    }

    public var canonicalName: String {
        "(\(elements.map(\.canonicalName).joined(separator: ",")))"
    }

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

        let sizeOfHeads = elements
            .map(\.headSize)
            .reduce(0, +)

        var (heads, tails) = (Data(), Data())
        for element in elements {
            let head: Data, tail: Data
            if element.isDynamic {
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

    // treats instance of self as a prototype with values as a placeholders that signify the type of
    // the value to decode.
    // This way the Tuple can be used during runtime without knowing the types of data in advance:
    // just construct a prototype tuple and decode the data to it.
    public mutating func decode(from data: Data, offset: inout Int) throws {
        let startOffset = offset
        // -1 to mark that tailEnd wasn't modified
        var tailEnd = -1
        for i in (0..<elements.count) {
            if elements[i].isDynamic {
                let tailOffset = try Sol.UInt256(from: data, offset: &offset)

                guard tailOffset < Int.max else {
                    throw SolAbiDecodingError.outOfBounds
                }
                var absoluteTailOffset = startOffset + Int(tailOffset)

                guard absoluteTailOffset < data.count else {
                    throw SolAbiDecodingError.outOfBounds
                }

                try elements[i].decode(from: data, offset: &absoluteTailOffset)

                tailEnd = absoluteTailOffset
            } else {
                try elements[i].decode(from: data, offset: &offset)
            }
        }
        // by the end of the loop the offset will go past the `heads` part
        // and we must jump to the last element's tail end, if there're any tails
        if tailEnd != -1 {
            offset = tailEnd
        }
    }

    public func encodePacked() -> Data {
        let result = elements.map { $0.encodePacked() }.reduce(Data(), +)
        return result
    }
}

// useful for expressing Solidity Tuple as a Swift struct - in that case
// it can be encoded and decoded using default implementations, just
// provide array of key paths to the tuple elements
public protocol SolKeyPathTuple {
    static var keyPaths: [AnyKeyPath] { get }
}

extension SolKeyPathTuple {
    public var elements: [SolAbiEncodable] {
        get {
            let result = Self.keyPaths.compactMap { self[keyPath: $0] as? SolAbiEncodable }
            return result
        }
        set {
            for (keyPath, element) in zip(Self.keyPaths, newValue) {
                // the keyPath we get has a concrete Value type which is not
                // the SolAbiEncodable type (type of element). Force-casting to WritableKeyPath fails
                // so we use unsafeBitCast.
                let kp = unsafeBitCast(keyPath, to: WritableKeyPath<Self, SolAbiEncodable>.self)
                self[keyPath: kp] = element
            }
        }
    }
}

extension Sol {
    public struct EmptyTuple: SolEncodableTuple, SolKeyPathTuple {
        public static var keyPaths: [AnyKeyPath] = []

        public init() {}
    }
}
