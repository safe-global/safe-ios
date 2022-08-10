// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum SafeToken {
    public struct allowance: SolContractFunction, SolKeyPathTuple {
        public var owner: Sol.Address
        public var spender: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.owner,
             \Self.spender
        ]

        public init(owner : Sol.Address, spender : Sol.Address) {
            self.owner = owner
            self.spender = spender
        }

        public init() {
            self.init(owner: .init(), spender: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.UInt256) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct approve: SolContractFunction, SolKeyPathTuple {
        public var spender: Sol.Address
        public var amount: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.spender,
             \Self.amount
        ]

        public init(spender : Sol.Address, amount : Sol.UInt256) {
            self.spender = spender
            self.amount = amount
        }

        public init() {
            self.init(spender: .init(), amount: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct balanceOf: SolContractFunction, SolKeyPathTuple {
        public var account: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.account
        ]

        public init(account : Sol.Address) {
            self.account = account
        }

        public init() {
            self.init(account: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.UInt256) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct decimals: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.UInt8

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.UInt8) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct decreaseAllowance: SolContractFunction, SolKeyPathTuple {
        public var spender: Sol.Address
        public var subtractedValue: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.spender,
             \Self.subtractedValue
        ]

        public init(spender : Sol.Address, subtractedValue : Sol.UInt256) {
            self.spender = spender
            self.subtractedValue = subtractedValue
        }

        public init() {
            self.init(spender: .init(), subtractedValue: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct increaseAllowance: SolContractFunction, SolKeyPathTuple {
        public var spender: Sol.Address
        public var addedValue: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.spender,
             \Self.addedValue
        ]

        public init(spender : Sol.Address, addedValue : Sol.UInt256) {
            self.spender = spender
            self.addedValue = addedValue
        }

        public init() {
            self.init(spender: .init(), addedValue: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct name: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.String

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.String) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct owner: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Address

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Address) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct paused: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct renounceOwnership: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct rescueToken: SolContractFunction, SolKeyPathTuple {
        public var token: Sol.Address
        public var beneficiary: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.token,
             \Self.beneficiary
        ]

        public init(token : Sol.Address, beneficiary : Sol.Address) {
            self.token = token
            self.beneficiary = beneficiary
        }

        public init() {
            self.init(token: .init(), beneficiary: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct symbol: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.String

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.String) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct totalSupply: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.UInt256) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct transfer: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var amount: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.amount
        ]

        public init(to : Sol.Address, amount : Sol.UInt256) {
            self.to = to
            self.amount = amount
        }

        public init() {
            self.init(to: .init(), amount: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct transferFrom: SolContractFunction, SolKeyPathTuple {
        public var from: Sol.Address
        public var to: Sol.Address
        public var amount: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.from,
             \Self.to,
             \Self.amount
        ]

        public init(from : Sol.Address, to : Sol.Address, amount : Sol.UInt256) {
            self.from = from
            self.to = to
            self.amount = amount
        }

        public init() {
            self.init(from: .init(), to: .init(), amount: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bool) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct transferOwnership: SolContractFunction, SolKeyPathTuple {
        public var newOwner: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.newOwner
        ]

        public init(newOwner : Sol.Address) {
            self.newOwner = newOwner
        }

        public init() {
            self.init(newOwner: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct unpause: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }
}
