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

protocol EthContractFunction {}
protocol EthContractEvent {}
protocol EthContractError {}
