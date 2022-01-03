//
//  Erc20Token.swift
//  
//
//  Created by Dmitry Bespalov on 28.12.21.
//

import Foundation

// https://eips.ethereum.org/EIPS/eip-20
enum EthContract {}

extension EthContract {
    enum Erc20Token {
//        struct name: EthContractFunction {
//            struct Returns: SolTuple {
//                var name: Sol.String
//            }
//        }
//
//        struct symbol: EthContractFunction {
//            struct Returns: SolTuple {
//                var name: Sol.String
//            }
//        }
//
//        struct decimals: EthContractFunction {
//            struct Returns: SolTuple {
//                var name: Sol.UInt8
//            }
//        }
//
//        struct totalSupply: EthContractFunction {
//            struct Returns: SolTuple {
//                var totalSupply: Sol.UInt256
//            }
//        }
//
//        struct balanceOf: EthContractFunction {
//            var who: Sol.Address
//
//            struct Returns: SolTuple {
//                var balance: Sol.UInt256
//            }
//        }
//
//        struct allowance: EthContractFunction {
//            var owner: Sol.Address
//            var spender: Sol.Address
//
//            struct Returns: SolTuple {
//                var remaining: Sol.UInt256
//            }
//        }
//
//        struct transfer: EthContractFunction {
//            var to: Sol.Address
//            var value: Sol.UInt256
//
//            struct Returns: SolTuple {
//                var success: Sol.Bool
//            }
//        }
//
//        struct approve: EthContractFunction {
//            var spender: Sol.Address
//            var value: Sol.UInt256
//
//            struct Returns: SolTuple {
//                var success: Sol.Bool
//            }
//        }

        struct transferFrom {
            var from: Sol.Address
            var to: Sol.Address
            var value: Sol.UInt256

            struct Returns {
                var success: Sol.Bool
            }
        }
//
//        struct Transfer: EthContractEvent {
//            var from: Sol.Address
//            var to: Sol.Address
//            var value: Sol.UInt256
//        }
//
//        struct Approval: EthContractEvent {
//            var owner: Sol.Address
//            var spender: Sol.Address
//            var value: Sol.UInt256
//        }
    }
}

public protocol EthContractFunction: SolAbiEncodable {
//    var name: String { get }
//    var parameterList: String { get }
//    var signature: String { get }
//    var parameters: Sol.Tuple { get }
//    var selector: Sol.Bytes4 { get }
}

extension EthContractFunction {
//    public var name: String {
//        String(describing: type(of: self))
//    }
//
//    public var parameterList: String {
//        let list = parameters.elementAbiTypes.map(\.canonicalName).joined(separator: ",")
//        let result = "(\(list))"
//        return result
//    }
//
//    public var signature: String {
//        name + parameterList
//    }

//    public var parameters: Sol.Tuple {
//        let params = Mirror(reflecting: self).children.compactMap { $0.value as? Sol.Tuple.Element }
//        let tuple = Sol.Tuple(
//            elementAbiTypes: params.map(\.abiDescription),
//            elements: params)
//        return tuple
//    }

//    public var selector: Sol.Bytes4 {
//        fatalError()
//        // keccak256(signature)[0..<4]
//    }
//
//    public var abiDescription: Sol.AbiTypeDescription {
//        let tuple = parameters
//        let isDynamic = parameters.abiDescription.isDynamic
//        let result = Sol.AbiTypeDescription(
//            canonicalName: signature,
//            isDynamic: isDynamic,
//            headSize: isDynamic ? 32 : (selector.abiDescription.headSize + tuple.abiDescription.headSize)
//        )
//        return result
//    }
//
//    public func encode() -> Data {
//        /*
//         All in all, a call to the function f with parameters a_1, ..., a_n is encoded as
//
//         function_selector(f) enc((a_1, ..., a_n))
//
//         and the return values v_1, ..., v_k of f are encoded as
//
//         enc((v_1, ..., v_k))
//
//         i.e. the values are combined into a tuple and encoded.
//
//
//         The first four bytes of the call data for a function call specifies the function to be called. It is the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function. The signature is defined as the canonical expression of the basic prototype without data location specifier, i.e. the function name with the parenthesised list of parameter types. Parameter types are split by a single comma - no spaces are used.
//         */
//        let result = selector.encode() + parameters.encode()
//        return result
//    }
}

protocol EthContractEvent {}

protocol EthContractError {}

struct transferFrom {
    var from: Sol.Address
    var to: Sol.Address
    var value: Sol.UInt256

    struct Returns {
        var success: Sol.Bool
    }
}


extension transferFrom: SolKeyPathTuple {
    static var keyPaths: [AnyKeyPath] = [
        \Self.from as AnyKeyPath,
        \Self.to as AnyKeyPath,
        \Self.value as AnyKeyPath
    ]

    init() {
        from = .init()
        to = .init()
        value = .init()
    }
}

extension transferFrom.Returns: SolKeyPathTuple {
    static var keyPaths: [AnyKeyPath] = [\Self.success]

    init() { success = .init() }
}

//    init(from data: Data, offset: inout Int) throws {
//        let selector = try Sol.Bytes4(from: data, offset: &offset)
//        from = try Sol.Address(from: data, offset: &offset)
//        to = try Sol.Address(from: data, offset: &offset)
//        value = try Sol.UInt256(from: data, offset: &offset)
//
//        // checking after initializing all values because the selector
//        // computes itself from value types
//        if selector.storage != self.selector.storage {
//            throw SolAbiDecodingError.dataInvalid
//        }
//    }
//}

//extension EthContract.Erc20Token.transferFrom.Returns: AbiDecodable {
//    init(from data: Data, offset: inout Int) throws {
//        let tuple = try Sol.Tuple.elements(from: data , offset: &offset, abiTypes: [(Sol.Bool.self, false)])
//        success = tuple[0] as! Sol.Bool
//    }
//}
