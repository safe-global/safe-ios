//
//  File.swift
//
//
//  Created by Dmitry Bespalov on 03.01.22.
//

import Foundation

public enum ERC20 {
    public struct transferFrom: SolContractFunction, SolKeyPathTuple {
        public var from: Sol.Address
        public var to: Sol.Address
        public var value: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [\Self.from, \Self.to, \Self.value]

        public init() {
            from = .init()
            to = .init()
            value = .init()
        }

        public init(from: Sol.Address, to: Sol.Address, value: Sol.UInt256) {
            self.from = from
            self.to = to
            self.value = value
        }

        public struct Returns: SolKeyPathTuple {
            public var success: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [\Self.success]

            public init() {
                success = .init()
            }
            public init(success: Sol.Bool) {
                self.success = success
            }
        }
    }
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
}
