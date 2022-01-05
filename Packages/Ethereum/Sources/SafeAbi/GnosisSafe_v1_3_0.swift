// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum GnosisSafe_v1_3_0 {
    public struct VERSION: SolContractFunction, SolKeyPathTuple {


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

    public struct addOwnerWithThreshold: SolContractFunction, SolKeyPathTuple {
        public var owner: Sol.Address
        public var _threshold: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.owner,
             \Self._threshold
        ]

        public init(owner : Sol.Address, _threshold : Sol.UInt256) {
            self.owner = owner
            self._threshold = _threshold
        }

        public init() {
            self.init(owner: .init(), _threshold: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct approveHash: SolContractFunction, SolKeyPathTuple {
        public var hashToApprove: Sol.Bytes32

        public static var keyPaths: [AnyKeyPath] = [
            \Self.hashToApprove
        ]

        public init(hashToApprove : Sol.Bytes32) {
            self.hashToApprove = hashToApprove
        }

        public init() {
            self.init(hashToApprove: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct approvedHashes: SolContractFunction, SolKeyPathTuple {
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

    public struct changeThreshold: SolContractFunction, SolKeyPathTuple {
        public var _threshold: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self._threshold
        ]

        public init(_threshold : Sol.UInt256) {
            self._threshold = _threshold
        }

        public init() {
            self.init(_threshold: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct checkNSignatures: SolContractFunction, SolKeyPathTuple {
        public var dataHash: Sol.Bytes32
        public var data: Sol.Bytes
        public var signatures: Sol.Bytes
        public var requiredSignatures: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.dataHash,
             \Self.data,
             \Self.signatures,
             \Self.requiredSignatures
        ]

        public init(dataHash : Sol.Bytes32, data : Sol.Bytes, signatures : Sol.Bytes, requiredSignatures : Sol.UInt256) {
            self.dataHash = dataHash
            self.data = data
            self.signatures = signatures
            self.requiredSignatures = requiredSignatures
        }

        public init() {
            self.init(dataHash: .init(), data: .init(), signatures: .init(), requiredSignatures: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct checkSignatures: SolContractFunction, SolKeyPathTuple {
        public var dataHash: Sol.Bytes32
        public var data: Sol.Bytes
        public var signatures: Sol.Bytes

        public static var keyPaths: [AnyKeyPath] = [
            \Self.dataHash,
             \Self.data,
             \Self.signatures
        ]

        public init(dataHash : Sol.Bytes32, data : Sol.Bytes, signatures : Sol.Bytes) {
            self.dataHash = dataHash
            self.data = data
            self.signatures = signatures
        }

        public init() {
            self.init(dataHash: .init(), data: .init(), signatures: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct disableModule: SolContractFunction, SolKeyPathTuple {
        public var prevModule: Sol.Address
        public var module: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.prevModule,
             \Self.module
        ]

        public init(prevModule : Sol.Address, module : Sol.Address) {
            self.prevModule = prevModule
            self.module = module
        }

        public init() {
            self.init(prevModule: .init(), module: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct domainSeparator: SolContractFunction, SolKeyPathTuple {


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

    public struct enableModule: SolContractFunction, SolKeyPathTuple {
        public var module: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.module
        ]

        public init(module : Sol.Address) {
            self.module = module
        }

        public init() {
            self.init(module: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct encodeTransactionData: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8
        public var safeTxGas: Sol.UInt256
        public var baseGas: Sol.UInt256
        public var gasPrice: Sol.UInt256
        public var gasToken: Sol.Address
        public var refundReceiver: Sol.Address
        public var _nonce: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation,
             \Self.safeTxGas,
             \Self.baseGas,
             \Self.gasPrice,
             \Self.gasToken,
             \Self.refundReceiver,
             \Self._nonce
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8, safeTxGas : Sol.UInt256, baseGas : Sol.UInt256, gasPrice : Sol.UInt256, gasToken : Sol.Address, refundReceiver : Sol.Address, _nonce : Sol.UInt256) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
            self.safeTxGas = safeTxGas
            self.baseGas = baseGas
            self.gasPrice = gasPrice
            self.gasToken = gasToken
            self.refundReceiver = refundReceiver
            self._nonce = _nonce
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init(), safeTxGas: .init(), baseGas: .init(), gasPrice: .init(), gasToken: .init(), refundReceiver: .init(), _nonce: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bytes

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bytes) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct execTransaction: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8
        public var safeTxGas: Sol.UInt256
        public var baseGas: Sol.UInt256
        public var gasPrice: Sol.UInt256
        public var gasToken: Sol.Address
        public var refundReceiver: Sol.Address
        public var signatures: Sol.Bytes

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation,
             \Self.safeTxGas,
             \Self.baseGas,
             \Self.gasPrice,
             \Self.gasToken,
             \Self.refundReceiver,
             \Self.signatures
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8, safeTxGas : Sol.UInt256, baseGas : Sol.UInt256, gasPrice : Sol.UInt256, gasToken : Sol.Address, refundReceiver : Sol.Address, signatures : Sol.Bytes) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
            self.safeTxGas = safeTxGas
            self.baseGas = baseGas
            self.gasPrice = gasPrice
            self.gasToken = gasToken
            self.refundReceiver = refundReceiver
            self.signatures = signatures
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init(), safeTxGas: .init(), baseGas: .init(), gasPrice: .init(), gasToken: .init(), refundReceiver: .init(), signatures: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var success: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self.success
            ]

            public init(success : Sol.Bool) {
                self.success = success
            }

            public init() {
                self.init(success: .init())
            }
        }
    }

    public struct execTransactionFromModule: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var success: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [
                \Self.success
            ]

            public init(success : Sol.Bool) {
                self.success = success
            }

            public init() {
                self.init(success: .init())
            }
        }
    }

    public struct execTransactionFromModuleReturnData: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var success: Sol.Bool
            public var returnData: Sol.Bytes

            public static var keyPaths: [AnyKeyPath] = [
                \Self.success,
                 \Self.returnData
            ]

            public init(success : Sol.Bool, returnData : Sol.Bytes) {
                self.success = success
                self.returnData = returnData
            }

            public init() {
                self.init(success: .init(), returnData: .init())
            }
        }
    }

    public struct getChainId: SolContractFunction, SolKeyPathTuple {


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

    public struct getModulesPaginated: SolContractFunction, SolKeyPathTuple {
        public var start: Sol.Address
        public var pageSize: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.start,
             \Self.pageSize
        ]

        public init(start : Sol.Address, pageSize : Sol.UInt256) {
            self.start = start
            self.pageSize = pageSize
        }

        public init() {
            self.init(start: .init(), pageSize: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var array: Sol.Array<Sol.Address>
            public var next: Sol.Address

            public static var keyPaths: [AnyKeyPath] = [
                \Self.array,
                 \Self.next
            ]

            public init(array : Sol.Array<Sol.Address>, next : Sol.Address) {
                self.array = array
                self.next = next
            }

            public init() {
                self.init(array: .init(), next: .init())
            }
        }
    }

    public struct getOwners: SolContractFunction, SolKeyPathTuple {


        public static var keyPaths: [AnyKeyPath] = [

        ]



        public init() {

        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Array<Sol.Address>

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Array<Sol.Address>) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct getStorageAt: SolContractFunction, SolKeyPathTuple {
        public var offset: Sol.UInt256
        public var length: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.offset,
             \Self.length
        ]

        public init(offset : Sol.UInt256, length : Sol.UInt256) {
            self.offset = offset
            self.length = length
        }

        public init() {
            self.init(offset: .init(), length: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bytes

            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]

            public init(_arg0 : Sol.Bytes) {
                self._arg0 = _arg0
            }

            public init() {
                self.init(_arg0: .init())
            }
        }
    }

    public struct getThreshold: SolContractFunction, SolKeyPathTuple {


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

    public struct getTransactionHash: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8
        public var safeTxGas: Sol.UInt256
        public var baseGas: Sol.UInt256
        public var gasPrice: Sol.UInt256
        public var gasToken: Sol.Address
        public var refundReceiver: Sol.Address
        public var _nonce: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation,
             \Self.safeTxGas,
             \Self.baseGas,
             \Self.gasPrice,
             \Self.gasToken,
             \Self.refundReceiver,
             \Self._nonce
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8, safeTxGas : Sol.UInt256, baseGas : Sol.UInt256, gasPrice : Sol.UInt256, gasToken : Sol.Address, refundReceiver : Sol.Address, _nonce : Sol.UInt256) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
            self.safeTxGas = safeTxGas
            self.baseGas = baseGas
            self.gasPrice = gasPrice
            self.gasToken = gasToken
            self.refundReceiver = refundReceiver
            self._nonce = _nonce
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init(), safeTxGas: .init(), baseGas: .init(), gasPrice: .init(), gasToken: .init(), refundReceiver: .init(), _nonce: .init())
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

    public struct isModuleEnabled: SolContractFunction, SolKeyPathTuple {
        public var module: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.module
        ]

        public init(module : Sol.Address) {
            self.module = module
        }

        public init() {
            self.init(module: .init())
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

    public struct isOwner: SolContractFunction, SolKeyPathTuple {
        public var owner: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.owner
        ]

        public init(owner : Sol.Address) {
            self.owner = owner
        }

        public init() {
            self.init(owner: .init())
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

    public struct nonce: SolContractFunction, SolKeyPathTuple {


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

    public struct removeOwner: SolContractFunction, SolKeyPathTuple {
        public var prevOwner: Sol.Address
        public var owner: Sol.Address
        public var _threshold: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [
            \Self.prevOwner,
             \Self.owner,
             \Self._threshold
        ]

        public init(prevOwner : Sol.Address, owner : Sol.Address, _threshold : Sol.UInt256) {
            self.prevOwner = prevOwner
            self.owner = owner
            self._threshold = _threshold
        }

        public init() {
            self.init(prevOwner: .init(), owner: .init(), _threshold: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct requiredTxGas: SolContractFunction, SolKeyPathTuple {
        public var to: Sol.Address
        public var value: Sol.UInt256
        public var data: Sol.Bytes
        public var operation: Sol.UInt8

        public static var keyPaths: [AnyKeyPath] = [
            \Self.to,
             \Self.value,
             \Self.data,
             \Self.operation
        ]

        public init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8) {
            self.to = to
            self.value = value
            self.data = data
            self.operation = operation
        }

        public init() {
            self.init(to: .init(), value: .init(), data: .init(), operation: .init())
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

    public struct setFallbackHandler: SolContractFunction, SolKeyPathTuple {
        public var handler: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.handler
        ]

        public init(handler : Sol.Address) {
            self.handler = handler
        }

        public init() {
            self.init(handler: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct setGuard: SolContractFunction, SolKeyPathTuple {
        public var `guard`: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.`guard`
        ]

        public init(`guard` : Sol.Address) {
            self.`guard` = `guard`
        }

        public init() {
            self.init(guard: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct setup: SolContractFunction, SolKeyPathTuple {
        public var _owners: Sol.Array<Sol.Address>
        public var _threshold: Sol.UInt256
        public var to: Sol.Address
        public var data: Sol.Bytes
        public var fallbackHandler: Sol.Address
        public var paymentToken: Sol.Address
        public var payment: Sol.UInt256
        public var paymentReceiver: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self._owners,
             \Self._threshold,
             \Self.to,
             \Self.data,
             \Self.fallbackHandler,
             \Self.paymentToken,
             \Self.payment,
             \Self.paymentReceiver
        ]

        public init(_owners : Sol.Array<Sol.Address>, _threshold : Sol.UInt256, to : Sol.Address, data : Sol.Bytes, fallbackHandler : Sol.Address, paymentToken : Sol.Address, payment : Sol.UInt256, paymentReceiver : Sol.Address) {
            self._owners = _owners
            self._threshold = _threshold
            self.to = to
            self.data = data
            self.fallbackHandler = fallbackHandler
            self.paymentToken = paymentToken
            self.payment = payment
            self.paymentReceiver = paymentReceiver
        }

        public init() {
            self.init(_owners: .init(), _threshold: .init(), to: .init(), data: .init(), fallbackHandler: .init(), paymentToken: .init(), payment: .init(), paymentReceiver: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct signedMessages: SolContractFunction, SolKeyPathTuple {
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

    public struct simulateAndRevert: SolContractFunction, SolKeyPathTuple {
        public var targetContract: Sol.Address
        public var calldataPayload: Sol.Bytes

        public static var keyPaths: [AnyKeyPath] = [
            \Self.targetContract,
             \Self.calldataPayload
        ]

        public init(targetContract : Sol.Address, calldataPayload : Sol.Bytes) {
            self.targetContract = targetContract
            self.calldataPayload = calldataPayload
        }

        public init() {
            self.init(targetContract: .init(), calldataPayload: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }

    public struct swapOwner: SolContractFunction, SolKeyPathTuple {
        public var prevOwner: Sol.Address
        public var oldOwner: Sol.Address
        public var newOwner: Sol.Address

        public static var keyPaths: [AnyKeyPath] = [
            \Self.prevOwner,
             \Self.oldOwner,
             \Self.newOwner
        ]

        public init(prevOwner : Sol.Address, oldOwner : Sol.Address, newOwner : Sol.Address) {
            self.prevOwner = prevOwner
            self.oldOwner = oldOwner
            self.newOwner = newOwner
        }

        public init() {
            self.init(prevOwner: .init(), oldOwner: .init(), newOwner: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }
}
