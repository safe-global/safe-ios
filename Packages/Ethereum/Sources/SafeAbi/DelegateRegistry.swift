// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum DelegateRegistry {
    public struct delegation: SolContractFunction, SolKeyPathTuple {
        public var _arg0: Sol.Address
        public var _arg1: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self._arg0,
             \Self._arg1
        ]

        public init(_arg0 : Sol.Address, _arg1 : Sol.Bytes32) {
            self._arg0 = _arg0
            self._arg1 = _arg1
        }

        public init() {
            self.init(_arg0: .init(), _arg1: .init())
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

    public struct setDelegate: SolContractFunction, SolKeyPathTuple {
        public var id: Sol.Bytes32
        public var delegate: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.id,
             \Self.delegate
        ]

        public init(id : Sol.Bytes32, delegate : Sol.Address) {
            self.id = id
            self.delegate = delegate
        }

        public init() {
            self.init(id: .init(), delegate: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct clearDelegate: SolContractFunction, SolKeyPathTuple {
        public var id: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.id
        ]

        public init(id : Sol.Bytes32) {
            self.id = id
        }

        public init() {
            self.init(id: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }
}
