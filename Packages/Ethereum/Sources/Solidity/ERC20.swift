//
//  File.swift
//
//
//  Created by Dmitry Bespalov on 03.01.22.
//

import Foundation

public enum ERC20 {
    public struct name: SolContractFunction, SolKeyPathTuple {
        public static var keyPaths: [AnyKeyPath] = []

        public init() {}

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var name: Sol.String

            public static var keyPaths: [AnyKeyPath] = [\Self.name]

            public init() { self.init(name: .init()) }

            public init(name: Sol.String) {
                self.name = name
            }
        }
    }

    public struct symbol: SolContractFunction, SolKeyPathTuple {
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var symbol: Sol.String

            public static var keyPaths: [AnyKeyPath] = [\Self.symbol]

            public init(name: Sol.String) {
                self.symbol = name
            }

            public init() { self.init(name: .init()) }
        }
        public static var keyPaths: [AnyKeyPath] = []
        public init() {}
    }

    public struct decimals: SolContractFunction, SolKeyPathTuple {
        public static var keyPaths: [AnyKeyPath] = []

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var decimals: Sol.UInt8

            public static var keyPaths: [AnyKeyPath] = [\Self.decimals]

            public init(decimals: Sol.UInt8) {
                self.decimals = decimals
            }

            public init() { self.init(decimals: .init()) }
        }

        public init() {}
    }

    public struct totalSupply: SolContractFunction, SolKeyPathTuple {
        public static var keyPaths: [AnyKeyPath] = []

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var totalSupply: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [\Self.totalSupply]

            public init(totalSupply: Sol.UInt256) {
                self.totalSupply = totalSupply
            }

            public init() { self.init(totalSupply: .init()) }
        }
        public init() {}
    }

    public struct balanceOf: SolContractFunction, SolKeyPathTuple {
        public var who: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [\Self.who]

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var balance: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [\Self.balance]

            public init(balance: Sol.UInt256) {
                self.balance = balance
            }

            public init() { self.init(balance: .init()) }
        }
        public init(who: Sol.Address) {
            self.who = who
        }

        public init() { self.init(who: .init()) }
    }

    public struct allowance: SolContractFunction, SolKeyPathTuple {
        public var owner: Sol.Address
        public var spender: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [\Self.owner, \Self.spender]

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var remaining: Sol.UInt256

            public static var keyPaths: [AnyKeyPath] = [\Self.remaining]

            public init(remaining: Sol.UInt256) {
                self.remaining = remaining
            }

            public init() { self.init(remaining: .init()) }
        }
        public init(owner: Sol.Address, spender: Sol.Address) {
            self.owner = owner
            self.spender = spender
        }
        public init() { self.init(owner: .init(), spender: .init()) }
    }

    public struct transfer: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [\Self.to, \Self.value]

        public typealias Returns = ReturnsSuccess

        public init(to: Sol.Address, value: Sol.UInt256) {
            self.to = to
            self.value = value
        }

        public init() { self.init(to: .init(), value: .init()) }
    }

    public struct transferFrom: SolContractFunction, SolKeyPathTuple {
        public var from: Sol.Address
        public var to: Sol.Address
        public var value: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [\Self.from, \Self.to, \Self.value]

        public init(from: Sol.Address, to: Sol.Address, value: Sol.UInt256) {
            self.from = from
            self.to = to
            self.value = value
        }

        public init() {
            self.init(from: .init(), to: .init(), value: .init())
        }

        public typealias Returns = ReturnsSuccess
    }

    public struct approve: SolContractFunction, SolKeyPathTuple {
        public var spender: Sol.Address
        public var value: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [\Self.spender, \Self.value]

        public typealias Returns = ReturnsSuccess

        public init(spender: Sol.Address, value: Sol.UInt256) {
            self.spender = spender
            self.value = value
        }

        public init() { self.init(spender: .init(), value: .init()) }
    }

    public struct ReturnsSuccess: SolEncodableTuple, SolKeyPathTuple {
        public var success: Sol.Bool

        public static var keyPaths: [AnyKeyPath] = [\Self.success]

        public init(success: Sol.Bool) {
            self.success = success
        }
        public init() { self.init(success: .init()) }
    }
}
