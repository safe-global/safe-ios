// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum VestingPool {
    public struct addVesting: SolContractFunction, SolKeyPathTuple {
        public var account: Sol.Address
        public var curveType: Sol.UInt8
        public var managed: Sol.Bool
        public var durationWeeks: Sol.UInt16
        public var startDate: Sol.UInt64
        public var amount: Sol.UInt128

        public static var keyPaths: [AnyKeyPath] = [
            \Self.account,
             \Self.curveType,
             \Self.managed,
             \Self.durationWeeks,
             \Self.startDate,
             \Self.amount
        ]

        public init(account : Sol.Address, curveType : Sol.UInt8, managed : Sol.Bool, durationWeeks : Sol.UInt16, startDate : Sol.UInt64, amount : Sol.UInt128) {
            self.account = account
            self.curveType = curveType
            self.managed = managed
            self.durationWeeks = durationWeeks
            self.startDate = startDate
            self.amount = amount
        }

        public init() {
            self.init(account: .init(), curveType: .init(), managed: .init(), durationWeeks: .init(), startDate: .init(), amount: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct calculateVestedAmount: SolContractFunction, SolKeyPathTuple {
        public var vestingId: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.vestingId
        ]

        public init(vestingId : Sol.Bytes32) {
            self.vestingId = vestingId
        }

        public init() {
            self.init(vestingId: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var vestedAmount: Sol.UInt128
            public var claimedAmount: Sol.UInt128

            public static var keyPaths: [AnyKeyPath] = [
                \Self.vestedAmount,
                 \Self.claimedAmount
            ]

            public init(vestedAmount : Sol.UInt128, claimedAmount : Sol.UInt128) {
                self.vestedAmount = vestedAmount
                self.claimedAmount = claimedAmount
            }

            public init() {
                self.init(vestedAmount: .init(), claimedAmount: .init())
            }
        }
    }

    public struct cancelVesting: SolContractFunction, SolKeyPathTuple {
        public var vestingId: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.vestingId
        ]

        public init(vestingId : Sol.Bytes32) {
            self.vestingId = vestingId
        }

        public init() {
            self.init(vestingId: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct claimVestedTokens: SolContractFunction, SolKeyPathTuple {
        public var vestingId: Sol.Bytes32
        public var beneficiary: Sol.Address
        public var tokensToClaim: Sol.UInt128

        public static var keyPaths: [AnyKeyPath] = [
            \Self.vestingId,
             \Self.beneficiary,
             \Self.tokensToClaim
        ]

        public init(vestingId : Sol.Bytes32, beneficiary : Sol.Address, tokensToClaim : Sol.UInt128) {
            self.vestingId = vestingId
            self.beneficiary = beneficiary
            self.tokensToClaim = tokensToClaim
        }

        public init() {
            self.init(vestingId: .init(), beneficiary: .init(), tokensToClaim: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct pauseVesting: SolContractFunction, SolKeyPathTuple {
        public var vestingId: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.vestingId
        ]

        public init(vestingId : Sol.Bytes32) {
            self.vestingId = vestingId
        }

        public init() {
            self.init(vestingId: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct poolManager: SolContractFunction, SolKeyPathTuple {


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

    public struct token: SolContractFunction, SolKeyPathTuple {


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

    public struct tokensAvailableForVesting: SolContractFunction, SolKeyPathTuple {


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

    public struct totalTokensInVesting: SolContractFunction, SolKeyPathTuple {


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

    public struct unpauseVesting: SolContractFunction, SolKeyPathTuple {
        public var vestingId: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.vestingId
        ]

        public init(vestingId : Sol.Bytes32) {
            self.vestingId = vestingId
        }

        public init() {
            self.init(vestingId: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct vestingHash: SolContractFunction, SolKeyPathTuple {
        public var account: Sol.Address
        public var curveType: Sol.UInt8
        public var managed: Sol.Bool
        public var durationWeeks: Sol.UInt16
        public var startDate: Sol.UInt64
        public var amount: Sol.UInt128

        public static var keyPaths: [AnyKeyPath] = [
            \Self.account,
             \Self.curveType,
             \Self.managed,
             \Self.durationWeeks,
             \Self.startDate,
             \Self.amount
        ]

        public init(account : Sol.Address, curveType : Sol.UInt8, managed : Sol.Bool, durationWeeks : Sol.UInt16, startDate : Sol.UInt64, amount : Sol.UInt128) {
            self.account = account
            self.curveType = curveType
            self.managed = managed
            self.durationWeeks = durationWeeks
            self.startDate = startDate
            self.amount = amount
        }

        public init() {
            self.init(account: .init(), curveType: .init(), managed: .init(), durationWeeks: .init(), startDate: .init(), amount: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var vestingId: Sol.Bytes32

            public static var keyPaths: [AnyKeyPath] = [
                \Self.vestingId
            ]

            public init(vestingId : Sol.Bytes32) {
                self.vestingId = vestingId
            }

            public init() {
                self.init(vestingId: .init())
            }
        }
    }

    public struct vestings: SolContractFunction, SolKeyPathTuple {
        public var _arg0: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self._arg0
        ]

        public init(_arg0 : Sol.Bytes32) {
            self._arg0 = _arg0
        }

        public init() {
            self.init(_arg0: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var account: Sol.Address
            public var curveType: Sol.UInt8
            public var managed: Sol.Bool
            public var durationWeeks: Sol.UInt16
            public var startDate: Sol.UInt64
            public var amount: Sol.UInt128
            public var amountClaimed: Sol.UInt128
            public var pausingDate: Sol.UInt64
            public var cancelled: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self.account,
                 \Self.curveType,
                 \Self.managed,
                 \Self.durationWeeks,
                 \Self.startDate,
                 \Self.amount,
                 \Self.amountClaimed,
                 \Self.pausingDate,
                 \Self.cancelled
            ]

            public init(account : Sol.Address, curveType : Sol.UInt8, managed : Sol.Bool, durationWeeks : Sol.UInt16, startDate : Sol.UInt64, amount : Sol.UInt128, amountClaimed : Sol.UInt128, pausingDate : Sol.UInt64, cancelled : Sol.Bool) {
                self.account = account
                self.curveType = curveType
                self.managed = managed
                self.durationWeeks = durationWeeks
                self.startDate = startDate
                self.amount = amount
                self.amountClaimed = amountClaimed
                self.pausingDate = pausingDate
                self.cancelled = cancelled
            }

            public init() {
                self.init(account: .init(), curveType: .init(), managed: .init(), durationWeeks: .init(), startDate: .init(), amount: .init(), amountClaimed: .init(), pausingDate: .init(), cancelled: .init())
            }
        }
    }
}
