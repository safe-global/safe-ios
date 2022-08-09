// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum Airdrop {
    public struct addVesting: SolContractFunction, SolKeyPathTuple {
        public var _arg0: Sol.Address
        public var _arg1: Sol.UInt8
        public var _arg2: Sol.Bool
        public var _arg3: Sol.UInt16
        public var _arg4: Sol.UInt64
        public var _arg5: Sol.UInt128

        public static var keyPaths: [AnyKeyPath] = [
            \Self._arg0,
             \Self._arg1,
             \Self._arg2,
             \Self._arg3,
             \Self._arg4,
             \Self._arg5
        ]

        public init(_arg0 : Sol.Address, _arg1 : Sol.UInt8, _arg2 : Sol.Bool, _arg3 : Sol.UInt16, _arg4 : Sol.UInt64, _arg5 : Sol.UInt128) {
            self._arg0 = _arg0
            self._arg1 = _arg1
            self._arg2 = _arg2
            self._arg3 = _arg3
            self._arg4 = _arg4
            self._arg5 = _arg5
        }

        public init() {
            self.init(_arg0: .init(), _arg1: .init(), _arg2: .init(), _arg3: .init(), _arg4: .init(), _arg5: .init())
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

    public struct claimUnusedTokens: SolContractFunction, SolKeyPathTuple {
        public var beneficiary: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.beneficiary
        ]

        public init(beneficiary : Sol.Address) {
            self.beneficiary = beneficiary
        }

        public init() {
            self.init(beneficiary: .init())
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

    public struct claimVestedTokensViaModule: SolContractFunction, SolKeyPathTuple {
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

    public struct initializeRoot: SolContractFunction, SolKeyPathTuple {
        public var _root: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self._root
        ]

        public init(_root : Sol.Bytes32) {
            self._root = _root
        }

        public init() {
            self.init(_root: .init())
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

    public struct redeem: SolContractFunction, SolKeyPathTuple {
        public var curveType: Sol.UInt8
        public var durationWeeks: Sol.UInt16
        public var startDate: Sol.UInt64
        public var amount: Sol.UInt128
        public var proof: Sol.Array<Sol.Bytes32>

        public static var keyPaths: [AnyKeyPath] = [
            \Self.curveType,
             \Self.durationWeeks,
             \Self.startDate,
             \Self.amount,
             \Self.proof
        ]

        public init(curveType : Sol.UInt8, durationWeeks : Sol.UInt16, startDate : Sol.UInt64, amount : Sol.UInt128, proof : Sol.Array<Sol.Bytes32>) {
            self.curveType = curveType
            self.durationWeeks = durationWeeks
            self.startDate = startDate
            self.amount = amount
            self.proof = proof
        }

        public init() {
            self.init(curveType: .init(), durationWeeks: .init(), startDate: .init(), amount: .init(), proof: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct redeemDeadline: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.UInt64

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.UInt64) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct root: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
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
