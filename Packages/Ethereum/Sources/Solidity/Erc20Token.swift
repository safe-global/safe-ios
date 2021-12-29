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
        struct name: EthContractFunction {
            struct Returns: SolTuple {
                var name: Sol.String
            }
        }

        struct symbol: EthContractFunction {
            struct Returns: SolTuple {
                var name: Sol.String
            }
        }

        struct decimals: EthContractFunction {
            struct Returns: SolTuple {
                var name: Sol.UInt8
            }
        }

        struct totalSupply: EthContractFunction {
            struct Returns: SolTuple {
                var totalSupply: Sol.UInt256
            }
        }

        struct balanceOf: EthContractFunction {
            var who: Sol.Address

            struct Returns: SolTuple {
                var balance: Sol.UInt256
            }
        }

        struct allowance: EthContractFunction {
            var owner: Sol.Address
            var spender: Sol.Address

            struct Returns: SolTuple {
                var remaining: Sol.UInt256
            }
        }

        struct transfer: EthContractFunction {
            var to: Sol.Address
            var value: Sol.UInt256

            struct Returns: SolTuple {
                var success: Sol.Bool
            }
        }

        struct approve: EthContractFunction {
            var spender: Sol.Address
            var value: Sol.UInt256

            struct Returns: SolTuple {
                var success: Bool
            }
        }

        struct transferFrom: EthContractFunction {
            var from: Sol.Address
            var to: Sol.Address
            var value: Sol.UInt256

            struct Returns: SolTuple {
                var success: Bool
            }
        }

        struct Transfer: EthContractEvent {
            var from: Sol.Address
            var to: Sol.Address
            var value: Sol.UInt256
        }

        struct Approval: EthContractEvent {
            var owner: Sol.Address
            var spender: Sol.Address
            var value: Sol.UInt256
        }
    }
}

public protocol EthContractFunction: AbiEncodable {
    /*
     All in all, a call to the function f with parameters a_1, ..., a_n is encoded as

     function_selector(f) enc((a_1, ..., a_n))

     and the return values v_1, ..., v_k of f are encoded as

     enc((v_1, ..., v_k))

     i.e. the values are combined into a tuple and encoded.


     The first four bytes of the call data for a function call specifies the function to be called. It is the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function. The signature is defined as the canonical expression of the basic prototype without data location specifier, i.e. the function name with the parenthesised list of parameter types. Parameter types are split by a single comma - no spaces are used.
     */
    associatedtype Returns: SolTuple
    var functionSelector: Data { get }
}

extension EthContractFunction {
    public var functionSelector: Data {
        // keccak256( name '(' param-canonical-type-names ')' )[0..<4]
        // name = name of the self type
        // params = reflected params as SolType
        let name = String(describing: type(of: self))
        let params = Mirror(reflecting: self).children
            .compactMap { $0 as? SolType }
            .map(\.canonicalTypeName)
        let signature = "\(name)(\(params.joined(separator: ",")))"
        #warning("Not implemented keccak")
//        let hash = keccak256(signature)
        let hash = Data([0, 0, 0, 0])
        let result = Data(hash[0..<4])
        return result
    }
}

protocol EthContractEvent {}

protocol EthContractError {}
