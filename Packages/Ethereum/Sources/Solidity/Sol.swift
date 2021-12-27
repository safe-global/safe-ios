//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 21.12.21.
//

import Foundation

public enum Sol {

}

public protocol SolType {}

//protocol SolTypeEncodable {
//    func encode() -> Data
//    static var isStatic: Bool { get }
//}
//
//
//protocol SolTupleEncodable {
//    func encode(types: [SolType.Type]) -> Data
//}
//
//extension SolTupleEncodable {
//    // 1. (T1,...,Tk) for k >= 0 and any types T1, …, Tk
//    //
//    // enc(X) = head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(k))
//    //
//    // where X = (X(1), ..., X(k)) and head and tail are defined for Ti as follows:
//    //
//    // if Ti is static:
//    //
//    // head(X(i)) = enc(X(i)) and tail(X(i)) = "" (the empty string)
//    //
//    // otherwise, i.e. if Ti is dynamic:
//    //
//    // head(X(i)) = enc(len( head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(i-1)) )); tail(X(i)) = enc(X(i))
//
//    // Note that in the dynamic case, head(X(i)) is well-defined since the lengths of the head parts
//    // only depend on the types and not
//    // the values. The value of head(X(i)) is the offset of the beginning of tail(X(i)) relative to the start of enc(X).
//    func encode(types: [SolType.Type]) -> Data {
//        // the types must be the same as actual types that we get, otherwise it is
//        // a programmer's error
//        let elements = Mirror(reflecting: self).children.compactMap { $0 as? SolType }
//        let reflectedTypes = elements.map { type(of: $0) }
//
//        precondition(reflectedTypes.count == types.count, "Not enough memebers for declared static types")
//        for (t, r) in zip(types, reflectedTypes) {
//            precondition(t == r, "Expected type '\(t)' but got '\(r)' during encoding")
//        }
//
//        // tails = data()
//        var heads = Data()
//        var tails = Data()
//
//        // for each element
//        for element in elements {
//            // head
//            let head: Data
//            let tail: Data
//
//            if type(of: element).isStatic {
//                // is static? = enc()
//                head = element.encode()
//                // tail
//                    // is static?  = nothing
//                tail = Data()
//            } else {
//                // else = sum of lengths of all heads and sum of lengths of tails before this, i.e. current offset.
//                    // sum of lengths of all heads is actually computable. this is going to be done over and over, so
//                    // we can actually precompute it.
//                        // if static? = len(enc())
//                        // else = len(enc(uint256))
//                let allHeadsLength = elements.map { element in
//                    if type(of: element).isStatic {
//                        // possible optimization: this depends on the type only
//                        return element.encode().count
//                    } else {
//                        // this depends on the type only and needed only for static types.
////                        return Sol.UInt256(0).encode().count
//                        #warning("uncomment")
//                        return 32
//                    }
//                }.reduce(0, +)
//
//                    // sum of lengths of all tails before is computable
//                        // if static? = 0
//                        // else = len(enc(element))
//                    // sum of lengths of all tails is in the currently encoded tails()
//
//                let precedingTailsLength = tails.count
//                let offset = allHeadsLength + precedingTailsLength
////                head = Sol.UInt256(offset).encode()
//                #warning("uncomment")
//                head = Data()
//
//                // else = enc()
//                tail = element.encode()
//            }
//
//            heads.append(head)
//            tails.append(tail)
//        }
//        // append tails to heads
//        let result = heads + tails
//        return result
//    }
//}
//
//protocol SolAbiTuple: SolType, SolTupleEncodable {
//    // only used in the isStatic default implementation.
//    static var types: [SolType.Type] { get }
//}
//
//// encode tuple
//extension SolAbiTuple {
//
//    func encode() -> Data {
//        encode(types: Self.types)
//    }
//
//
////     Definition: The following types are called “dynamic”:
////
////     bytes = true always
////     string = true always
////
////     T[k] for any dynamic T and any k >= 0 = depends on the type of T, ok
////     (T1,...,Tk) if Ti is dynamic for some 1 <= i <= k = depends on the type of element.
////     can't know at compile time, can i?
//
//    //
//    // All other types are called “static”.
//    static var isStatic: Bool {
//        // Tuple (T1,...,Tk) is dynamic iff Ti is dynamic for some 1 <= i <= k
//        // equivalent: if all of the elements are static.
//        types.allSatisfy { $0.isStatic } || types.isEmpty
//    }
//}
//
//// decode tuple
//
//
//
//// how to express myfunc(int[20])? I'll be able to encode it, but not decode it
//// without the '20' in the type name?
//
//
//protocol SolAbiFixedArray: SolType, SolTupleEncodable, CustomReflectable {
//    static var size: Int { get }
//    var elements: [Element] { get }
//    associatedtype Element: SolType
//}
//
//extension SolAbiFixedArray {
//    //    // T[k] is dynamic for any dynamic T and any k >= 0
//    //    // T[k] is static otherwise, i.e. for any static T
//    static var isStatic: Bool { Element.isStatic }
//
//    var customMirror: Mirror { elements.customMirror }
//
//    func encode() -> Data {
//        encode(types: elements.map { type(of: $0) })
//    }
//}
//
//extension Sol.Array: SolType, SolTupleEncodable, CustomReflectable {
//    var customMirror: Mirror {
//        elements.customMirror
//    }
//
//    // 3. T[] where X has k elements (k is assumed to be of type uint256):
//    //
//    // enc(X) = enc(k) enc([X[0], ..., X[k-1]])
//    // i.e. it is encoded as if it were an array of static size k, prefixed with the number of elements.
//    func encode() -> Data {
////        Sol.UInt256(elements.count).encode() + encode(types: elements.map { type(of: $0) } )
//        #warning("uncomment")
//        return Data()
//    }
//    //     T[] for any T = true always (always dynamic, i.e. never static)
//    static var isStatic: Bool { false }
//}
//
//extension Sol.Bytes: SolType {
//    static var isStatic: Bool { false }
//
//    func encode() -> Data {
//        fatalError("not implemented")
//    }
//}
//
////struct CustomTuple<Element>: SolAbiTuple {
////    static var types: [SolAbiType.Type] = []
////    // static stored properties are not supported in generic types! ffs!
////    var elements: [Element]
////}
//
//// then tuple is actually a `struct` with each element predefined.
//// can we then reflect on each one?
//
//
//// decode fixed array
////contract Token {
////    function transfer(address to, uint256 value) returns (bool success);
////    function transferFrom(address from, address to, uint256 value) returns (bool success);
////    function approve(address spender, uint256 value) returns (bool success);
////
////    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions.
////    function totalSupply() constant returns (uint256 supply) {}
////    function balanceOf(address owner) constant returns (uint256 balance);
////    function allowance(address owner, address spender) constant returns (uint256 remaining);
////
////    event Transfer(address indexed from, address indexed to, uint256 value);
////    event Approval(address indexed owner, address indexed spender, uint256 value);
////}
//
//extension Sol.Address: SolType {
//    func encode() -> Data {
//        fatalError("not implemented")
//    }
//
//    static var isStatic: Bool { false }
//}
//
//extension Sol.Bool: SolType {
//    func encode() -> Data {
//        fatalError("not implemented")
//    }
//
//    static var isStatic: Bool { false }
//}
//
//enum Token {
//    struct transfer {
//        var to: Sol.Address
//        var value: Sol.UInt256
//
//        struct Return {
//            var success: Sol.Bool
//        }
//
//        func result(from data: Data) throws -> Return {
//            fatalError("not implemented")
//        }
//    }
//}
//
//extension Token.transfer: SolAbiTuple {
//    static var types: [SolType.Type] {
//        #warning("UInt256")
//        return [Sol.Address.self, Sol.Address.self]
//    }
//}
//
//extension Token.transfer.Return: SolAbiTuple {
//    static var types: [SolType.Type] { [Sol.Bool.self] }
//}
//
//func encodeCall() throws {
//    // transfer
////    let call = Token.transfer(to: SolAbi.Address(), value: SolAbi.UInt256(1))
////    let params = call.encode()
////    // send in the transaction.
////    let output: Data = Data()
////    let result = try call.result(from: output)
//}
//
//
//// bytes = true always
//// string = true always
//// T[] for any T = true always
////extension SolAbi.Bytes: SolAbiType {
////}
//
//// tuple of (int, string) is dynamic
//// array of such tuples (int, string)[10] is dynamic
//// so the type depends on what is inside the tuple.
//
//// so if I'm an empty array of such tuples, I'll be expressed as
//// FixedArray<Tuple>(), i.e. the type information is lost until I put a single
//// element. I can't actually express the dynamic tuple type without the
//// hint of the expected schema.
//
//// hm, but the types are compiled. so I do have the schema. Stringy typing.
//
//// ((int,string)[10]) - canonical representation.
//// (int,string) --> Tuple<int,string>, etc.
//
//// I can express that if I init tuple with type info.
//// fixed array of tuples then needs the tuple info! but it doesn't have it.
//
//// tuple.static is wrong.
//
//// so as fixed array of something?
