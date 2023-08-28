//
//  EthRpc1.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import Foundation
import JsonRpc2
import Solidity

/// Namespace for the types defined in the Ethereum JSON-RPC 1.0 specification
///
/// See more:
///   - https://raw.githubusercontent.com/ethereum/eth1.0-apis/assembled-spec/openrpc.json
///   - https://eips.ethereum.org/EIPS/eip-1474
public enum EthRpc1 {
    public enum Transaction: Codable {
        case legacy(TransactionLegacy)
        case eip2930(Transaction2930)
        case eip1559(Transaction1559)
        /// not known type
        case unknown

        public init(from decoder: Decoder) throws {
            enum Key: String, CodingKey { case type }
            let container = try decoder.container(keyedBy: Key.self)
            var type = try container.decode(String.self, forKey: .type)

            if type.hasPrefix("0x") {
                type.removeFirst(2)
            }

            guard let byte = UInt8(type, radix: 16) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid transaction `type` value: \(type)")
                )
            }

            // Learn more:
            // https://eips.ethereum.org/EIPS/eip-1559
            // https://eips.ethereum.org/EIPS/eip-2930
            // https://eips.ethereum.org/EIPS/eip-2718

            // Type of a transaction with access list and chain Id. Defined in EIP-2930
            let EIP_2930_TYPE: UInt8 = 0x01

            // Type of a transaction with priority fee. Defined in EIP-1559
            let EIP_1559_TYPE: UInt8 = 0x02

            // Legacy transaction type value. Defined in EIP-2718
            let LEGACY_RANGE_TYPE: ClosedRange<UInt8> = (0xc0...0xfe)

            // All possible values for the 'type' according to EIP-2718
            let EIP_2718_RANGE_TYPE: ClosedRange<UInt8> = (0x00...0x7f)

            // Reserved value for the 'type' according to EIP-2718
            let EIP_2718_RESERVED_TYPE: UInt8 = 0xff

            switch byte {
            case EIP_2930_TYPE:
                self = try .eip2930(.init(from: decoder))
            case EIP_1559_TYPE:
                self = try .eip1559(.init(from: decoder))
            case LEGACY_RANGE_TYPE:
                self = try .legacy(.init(from: decoder))
            case EIP_2718_RANGE_TYPE:
                // backwards compatibility:
                // EIP-2718 transaction but we don't know it's type
                fallthrough
            case EIP_2718_RESERVED_TYPE:
                fallthrough
            default:
                self = .unknown
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .legacy(let value):
                try value.encode(to: encoder)
            case .eip2930(let value):
                try value.encode(to: encoder)
            case .eip1559(let value):
                try value.encode(to: encoder)
            case .unknown:
                var container = encoder.singleValueContainer()
                try container.encode([String: String]())
            }
        }
    }

    public struct TransactionLegacy: Codable {
        /// type according to EIP-2718
        ///
        /// Must be in range [0xc0, 0xfe]
        public var type: Quantity<Sol.UInt64> = .init(0xc0)

        public var nonce: Quantity<Sol.UInt64>?

        /// to address
        public var to: EthRpc1.Data?

        /// gas limit
        public var gas: Quantity<Sol.UInt64>?

        public var value: Quantity<Sol.UInt256>

        /// data data
        public var data: EthRpc1.Data

        /// The gas price willing to be paid by the sender in wei
        public var gasPrice: Quantity<Sol.UInt256>?

        /// Chain ID that this transaction is valid on.
        ///
        /// Used only in the response type
        public var chainId: Quantity<Sol.UInt256>?

        /// from address
        public var from: EthRpc1.Data?

        public var blockHash: EthRpc1.Data?

        public var blockNumber: Quantity<Sol.UInt256>?

        /// Transaction hash
        public var hash: EthRpc1.Data?

        public var transactionIndex: Quantity<Sol.UInt64>?

        /// Signature 'v' component
        public var v: Quantity<Sol.UInt256>?

        /// Signature 'r' component
        public var r: Quantity<Sol.UInt256>?

        /// Signature 's' component
        public var s: Quantity<Sol.UInt256>?

        public init(type: EthRpc1.Quantity<Sol.UInt64> = .init(0xc0), nonce: EthRpc1.Quantity<Sol.UInt64>?, to: EthRpc1.Data?, gas: EthRpc1.Quantity<Sol.UInt64>?, value: EthRpc1.Quantity<Sol.UInt256>, data: EthRpc1.Data, gasPrice: EthRpc1.Quantity<Sol.UInt256>?, chainId: EthRpc1.Quantity<Sol.UInt256>?, from: EthRpc1.Data?, blockHash: EthRpc1.Data?, blockNumber: EthRpc1.Quantity<Sol.UInt256>?, hash: EthRpc1.Data?, transactionIndex: EthRpc1.Quantity<Sol.UInt64>?, v: EthRpc1.Quantity<Sol.UInt256>?, r: EthRpc1.Quantity<Sol.UInt256>?, s: EthRpc1.Quantity<Sol.UInt256>?) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.data = data
            self.gasPrice = gasPrice
            self.chainId = chainId
            self.from = from
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.hash = hash
            self.transactionIndex = transactionIndex
            self.v = v
            self.r = r
            self.s = s
        }
    }

    /// EIP-2930 transaction.
    public struct Transaction2930: Codable {
        /// type according to EIP-2718
        ///
        /// Must be 0x01 per specification
        public var type: Quantity<Sol.UInt64> = .init(0x01)

        public var nonce: Quantity<Sol.UInt64>?

        /// to address
        public var to: EthRpc1.Data?

        /// gas limit
        public var gas: Quantity<Sol.UInt64>?

        public var value: Quantity<Sol.UInt256>

        /// data data
        public var data: EthRpc1.Data

        /// The gas price willing to be paid by the sender in wei
        public var gasPrice: Quantity<Sol.UInt256>?

        /// EIP-2930 access list
        public var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        public var chainId: Quantity<Sol.UInt256>

        /// from address
        public var from: EthRpc1.Data?

        public var blockHash: EthRpc1.Data?

        public var blockNumber: Quantity<Sol.UInt256>?

        /// Transaction hash
        public var hash: EthRpc1.Data?

        public var transactionIndex: Quantity<Sol.UInt64>?

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        public var yParity: Quantity<Sol.UInt256>?

        /// Signature 'r' component
        public var r: Quantity<Sol.UInt256>?

        /// Signature 's' component
        public var s: Quantity<Sol.UInt256>?

        public init(type: EthRpc1.Quantity<Sol.UInt64> = .init(0x01), nonce: EthRpc1.Quantity<Sol.UInt64>?, to: EthRpc1.Data?, gas: EthRpc1.Quantity<Sol.UInt64>?, value: EthRpc1.Quantity<Sol.UInt256>, data: EthRpc1.Data, gasPrice: EthRpc1.Quantity<Sol.UInt256>?, accessList: [EthRpc1.AccessListEntry], chainId: EthRpc1.Quantity<Sol.UInt256>, from: EthRpc1.Data?, blockHash: EthRpc1.Data?, blockNumber: EthRpc1.Quantity<Sol.UInt256>?, hash: EthRpc1.Data?, transactionIndex: EthRpc1.Quantity<Sol.UInt64>?, yParity: EthRpc1.Quantity<Sol.UInt256>?, r: EthRpc1.Quantity<Sol.UInt256>?, s: EthRpc1.Quantity<Sol.UInt256>?) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.data = data
            self.gasPrice = gasPrice
            self.accessList = accessList
            self.chainId = chainId
            self.from = from
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.hash = hash
            self.transactionIndex = transactionIndex
            self.yParity = yParity
            self.r = r
            self.s = s
        }
    }

    /// EIP-1559 transaction.
    public struct Transaction1559: Codable {
        /// type according to EIP-2718
        ///
        /// Must be 0x02 per specification
        public var type: Quantity<Sol.UInt64> = .init(0x02)

        public var nonce: Quantity<Sol.UInt64>?

        /// to address
        public var to: EthRpc1.Data? = nil

        /// gas limit
        public var gas: Quantity<Sol.UInt64>?

        public var value: Quantity<Sol.UInt256>

        /// data data
        public var data: EthRpc1.Data

        /// Maximum fee per gas the sender is willing to pay to miners in wei
        public var maxPriorityFeePerGas: Quantity<Sol.UInt256>?

        /// The maximum total fee per gas the sender is willing to pay (includes the network / base fee and miner / priority fee) in wei
        public var maxFeePerGas: Quantity<Sol.UInt256>?

        /// EIP-2930 access list
        public var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        public var chainId: Quantity<Sol.UInt256>

        /// from address
        public var from: EthRpc1.Data? = nil

        public var blockHash: EthRpc1.Data? = nil

        public var blockNumber: Quantity<Sol.UInt256>? = nil

        /// Transaction hash
        public var hash: EthRpc1.Data? = nil

        public var transactionIndex: Quantity<Sol.UInt64>? = nil

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        public var yParity: Quantity<Sol.UInt256>? = nil

        /// Signature 'r' component
        public var r: Quantity<Sol.UInt256>? = nil

        /// Signature 's' component
        public var s: Quantity<Sol.UInt256>? = nil

        public init(type: EthRpc1.Quantity<Sol.UInt64> = .init(0x02), nonce: EthRpc1.Quantity<Sol.UInt64>?, to: EthRpc1.Data? = nil, gas: EthRpc1.Quantity<Sol.UInt64>?, value: EthRpc1.Quantity<Sol.UInt256>, data: EthRpc1.Data, maxPriorityFeePerGas: EthRpc1.Quantity<Sol.UInt256>?, maxFeePerGas: EthRpc1.Quantity<Sol.UInt256>?, accessList: [EthRpc1.AccessListEntry], chainId: EthRpc1.Quantity<Sol.UInt256>, from: EthRpc1.Data? = nil, blockHash: EthRpc1.Data? = nil, blockNumber: EthRpc1.Quantity<Sol.UInt256>? = nil, hash: EthRpc1.Data? = nil, transactionIndex: EthRpc1.Quantity<Sol.UInt64>? = nil, yParity: EthRpc1.Quantity<Sol.UInt256>? = nil, r: EthRpc1.Quantity<Sol.UInt256>? = nil, s: EthRpc1.Quantity<Sol.UInt256>? = nil) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.data = data
            self.maxPriorityFeePerGas = maxPriorityFeePerGas
            self.maxFeePerGas = maxFeePerGas
            self.accessList = accessList
            self.chainId = chainId
            self.from = from
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.hash = hash
            self.transactionIndex = transactionIndex
            self.yParity = yParity
            self.r = r
            self.s = s
        }
    }

    public struct EstimateGasLegacyTransaction: Codable {
        public var type: Quantity<Sol.UInt64>?

        public var nonce: Quantity<Sol.UInt64>?

        /// to address
        public var to: EthRpc1.Data? = nil

        /// gas limit
        public var gas: Quantity<Sol.UInt64>?

        /// The gas price willing to be paid by the sender in wei
        public var gasPrice: Quantity<Sol.UInt256>?

        public var value: Quantity<Sol.UInt256>

        /// data data
        public var data: EthRpc1.Data

        /// Maximum fee per gas the sender is willing to pay to miners in wei
        public var maxPriorityFeePerGas: Quantity<Sol.UInt256>?

        /// The maximum total fee per gas the sender is willing to pay (includes the network / base fee and miner / priority fee) in wei
        public var maxFeePerGas: Quantity<Sol.UInt256>?

        /// from address
        public var from: EthRpc1.Data? = nil

        enum CodingKeys: String, CodingKey {
            case from, to, gas, gasPrice, maxPriorityFeePerGas, maxFeePerGas, value, data
        }

        public init(type: EthRpc1.Quantity<Sol.UInt64>?, nonce: EthRpc1.Quantity<Sol.UInt64>?, to: EthRpc1.Data? = nil, gas: EthRpc1.Quantity<Sol.UInt64>?, gasPrice: EthRpc1.Quantity<Sol.UInt256>?, value: EthRpc1.Quantity<Sol.UInt256>, data: EthRpc1.Data, maxPriorityFeePerGas: EthRpc1.Quantity<Sol.UInt256>?, maxFeePerGas: EthRpc1.Quantity<Sol.UInt256>?, from: EthRpc1.Data? = nil) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.gasPrice = gasPrice
            self.value = value
            self.data = data
            self.maxPriorityFeePerGas = maxPriorityFeePerGas
            self.maxFeePerGas = maxFeePerGas
            self.from = from
        }
    }

    public struct Log: Codable {
        public var removed: Bool?
        public var logIndex: String?
        public var transactionIndex: String?
        public var transactionHash: String?
        public var blockHash: String?
        public var blockNumber: String?
        public var address: String?
        public var data: String?
        public var topics: [String]?

        public init(removed: Bool?, logIndex: String?, transactionIndex: String?, transactionHash: String?, blockHash: String?, blockNumber: String?, address: String?, data: String?, topics: [String]?) {
            self.removed = removed
            self.logIndex = logIndex
            self.transactionIndex = transactionIndex
            self.transactionHash = transactionHash
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.address = address
            self.data = data
            self.topics = topics
        }
    }

    public struct ReceiptInfo: Codable {
        public var transactionHash: String

        public var transactionIndex: String

        public var blockHash: String

        public var blockNumber: String

        public var from: String

        /// Address of the receiver or null in a contract creation transaction.
        public var to: String?

        /// The sum of gas used by this transaction and all preceding transactions in the same block.
        public var cumulativeGasUsed: String

        /// The amount of gas used for this specific transaction alone.
        public var gasUsed: String

        /// The contract address created, if the transaction was a contract creation, otherwise null.
        public var contractAddress: String?

        public var logs: [Log]

        public var logsBloom: String

        /// The post-transaction state root. Only specified for transactions included before the Byzantium upgrade.
        public var root: String?

        /// Either 1 (success) or 0 (failure). Only specified for transactions included after the Byzantium upgrade.
        public var status: String?

        /// The actual value per gas deducted from the senders account. Before EIP-1559, this is equal to the transaction's gas price. After, it is equal to baseFeePerGas + min(maxFeePerGas - baseFeePerGas, maxPriorityFeePerGas).
        public var effectiveGasPrice: String?

        public init(transactionHash: String, transactionIndex: String, blockHash: String, blockNumber: String, from: String, to: String?, cumulativeGasUsed: String, gasUsed: String, contractAddress: String?, logs: [EthRpc1.Log], logsBloom: String, root: String?, status: String?, effectiveGasPrice: String?) {
            self.transactionHash = transactionHash
            self.transactionIndex = transactionIndex
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.from = from
            self.to = to
            self.cumulativeGasUsed = cumulativeGasUsed
            self.gasUsed = gasUsed
            self.contractAddress = contractAddress
            self.logs = logs
            self.logsBloom = logsBloom
            self.root = root
            self.status = status
            self.effectiveGasPrice = effectiveGasPrice
        }
    }

    /// Access list entry
    public struct AccessListEntry: Codable {
        public var address: EthRpc1.Data?
        public var storageKeys: [EthRpc1.Data]?

        public init(address: EthRpc1.Data?, storageKeys: [EthRpc1.Data]?) {
            self.address = address
            self.storageKeys = storageKeys
        }
    }
}

extension EthRpc1 {
    /// Returns the balance of the account of given address.
    public struct eth_getBalance: JsonRpc2Method, EthRpc1AccountParams {
        /// Account to get balance of
        public var address: EthRpc1.Data

        /// Block number or tag
        public var block: EthRpc1.BlockSpecifier

        /// Balance
        public typealias Return = Quantity<Sol.UInt256>

        public init(address: EthRpc1.Data, block: EthRpc1.BlockSpecifier) {
            self.address = address
            self.block = block
        }
    }

    /// Returns the number of the most recent block seen by this client
    public struct eth_blockNumber: JsonRpc2Method, EthRpc1EmptyParams {
        /// number of the latest block
        public typealias Return = Quantity<Sol.UInt256>

        public init() {}
    }


    /// Returns the current price per gas in wei.
    public struct eth_gasPrice: JsonRpc2Method, EthRpc1EmptyParams {
        /// Gas price
        public typealias Return = Quantity<Sol.UInt256>

        public init() {}
    }

    /// Executes a new message call immediately without creating a transaction on the block chain.
    public struct eth_call: JsonRpc2Method {
        /// Transaction. NOTE: `from` field MUST be present.
        public var transaction: Transaction
        /// Block number or tag
        public var block: EthRpc1.BlockSpecifier

        /// Return data
        public typealias Return = EthRpc1.Data

        public init(transaction: EthRpc1.Transaction, block: EthRpc1.BlockSpecifier) {
            self.transaction = transaction
            self.block = block
        }
    }

    public struct eth_callLegacyApi: JsonRpc2Method {
        public static var name: String { "eth_call" }

        public var transaction: EstimateGasLegacyTransaction

        public var block: EthRpc1.BlockSpecifier

        public typealias Return = EthRpc1.Data

        public init(transaction: EstimateGasLegacyTransaction, block: EthRpc1.BlockSpecifier) {
            self.transaction = transaction
            self.block = block
        }
    }

    /// Generates and returns an estimate of how much gas is necessary to allow the transaction to complete.
    public struct eth_estimateGas: EthEstimateGasAbi, JsonRpc2Method, EthRpc1TransactionParams {
        /// Transaction. NOTE: `from` field MUST be present.
        public var transaction: Transaction

        public init(transaction: EthRpc1.Transaction) {
            self.transaction = transaction
        }
    }

    public struct eth_estimateGasLegacyApi: EthEstimateGasAbi, JsonRpc2Method, EthRpc1TransactionParams {
        public static var name: String { "eth_estimateGas" }

        public var transaction: EstimateGasLegacyTransaction

        public init(transaction: EthRpc1.EstimateGasLegacyTransaction) {
            self.transaction = transaction
        }
    }

    /// Submits a raw transaction.
    public struct eth_sendRawTransaction: JsonRpc2Method, EthRpc1TransactionParams {
        /// Transaction as bytes
        public var transaction: EthRpc1.Data

        /// Transaction hash, or the zero hash if the transaction is not yet available
        public typealias Return = EthRpc1.Data

        public init(transaction: EthRpc1.Data) {
            self.transaction = transaction
        }
    }

    /// Creates new message call transaction or a contract creation, if the data field contains code.
    public struct eth_sendTransaction: JsonRpc2Method, EthRpc1TransactionParams {
        public var transaction: EthRpc1.EstimateGasLegacyTransaction

        /// the transaction hash, or the zero hash if the transaction is not yet available.
        public typealias Return = EthRpc1.Data

        public init(transaction: EthRpc1.EstimateGasLegacyTransaction) {
            self.transaction = transaction
        }
    }

    /// Returns the receipt of a transaction by transaction hash.
    public struct eth_getTransactionReceipt: JsonRpc2Method {
        public var transactionHash: EthRpc1.Data

        /// Receipt Information or null if transaction not found
        public typealias Return = ReceiptInfo?

        public init(transactionHash: EthRpc1.Data) {
            self.transactionHash = transactionHash
        }
    }

    /// Returns the number of transactions sent from an address.
    public struct eth_getTransactionCount: JsonRpc2Method, EthRpc1AccountParams {
        /// Account to get balance of
        public var address: EthRpc1.Data

        /// Block number or tag
        public var block: EthRpc1.BlockSpecifier

        /// Transaction count
        public typealias Return = Quantity<Sol.UInt64>

        public init(address: EthRpc1.Data, block: EthRpc1.BlockSpecifier) {
            self.address = address
            self.block = block
        }
    }

    /// Calculates an Ethereum-specific signature in the form of keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))
    public struct eth_sign: JsonRpc2Method {
        /// address to use for signing
        public var address: EthRpc1.Data

        /// data to sign
        public var message: EthRpc1.Data

        /// signature hash of the provided data
        public typealias Return = EthRpc1.Data

        public init(address: EthRpc1.Data, message: EthRpc1.Data) {
            self.address = address
            self.message = message
        }
    }
}

public protocol EthRpc1EmptyParams: Codable {
    init()
}

extension EthRpc1EmptyParams {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        _ = try container.decode([String].self)
        self.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([String]())
    }
}

// reusable codable implementation of account parameters for methods that query account state
public protocol EthRpc1AccountParams: Codable {
    var address: EthRpc1.Data { get set }
    var block: EthRpc1.BlockSpecifier { get set }
    init(address: EthRpc1.Data, block: EthRpc1.BlockSpecifier)
}

extension EthRpc1AccountParams {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let address = try container.decode(EthRpc1.Data.self)
        let block = try container.decode(EthRpc1.BlockSpecifier.self)
        self.init(address: address, block: block)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(block)
    }
}

public protocol EthRpc1TransactionParams: Codable {
    associatedtype Transaction: Codable
    var transaction: Transaction  { get set }
    init(transaction: Transaction)
}

extension EthRpc1TransactionParams {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let transaction = try container.decode(Transaction.self)
        self.init(transaction: transaction)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transaction)
    }
}

extension EthRpc1.eth_call: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let transaction = try container.decode(EthRpc1.Transaction.self)
        let block = try container.decode(EthRpc1.BlockSpecifier.self)
        self.init(transaction: transaction, block: block)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transaction)
        try container.encode(block)
    }
}

extension EthRpc1.eth_callLegacyApi: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let transaction = try container.decode(EthRpc1.EstimateGasLegacyTransaction.self)
        let block = try container.decode(EthRpc1.BlockSpecifier.self)
        self.init(transaction: transaction, block: block)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transaction)
        try container.encode(block)
    }
}

public protocol EthEstimateGasAbi {}

extension EthEstimateGasAbi where Self: JsonRpc2Method, Self: EthRpc1TransactionParams {
    public typealias Return = EthRpc1.Quantity<Sol.UInt64>
}

extension EthRpc1.eth_getTransactionReceipt: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let transaction = try container.decode(EthRpc1.Data.self)
        self.init(transactionHash: transaction)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transactionHash)
    }
}

extension EthRpc1.eth_sign: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let address = try container.decode(EthRpc1.Data.self)
        let message = try container.decode(EthRpc1.Data.self)
        self.init(address: address, message: message)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(message)
    }
}

extension EthRpc1 {
    public struct Quantity<T> where T: FixedWidthInteger {
        public var storage: T

        public init() {
            self.init(.init())
        }

        public init(_ value: T) {
            self.storage = value
        }
    }
}

extension EthRpc1.Quantity: Codable {
    // A Quantity value MUST be hex-encoded.
    // A Quantity value MUST be “0x”-prefixed.
    // A Quantity value MUST be expressed using the fewest possible hex digits per byte.
    // A Quantity value MUST express zero as “0x0”.

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard string.hasPrefix("0x") else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Quantity value MUST be 0x-prefixed",
                                      underlyingError: nil)
            )
        }

        guard let value = T(string.dropFirst(2), radix: 16) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Quantity value MUST be hex-encoded",
                                      underlyingError: nil)
            )
        }

        self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        let value: String = hex
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public var hex: String {
        let value: String
        if storage == 0 {
            value = "0x0"
        } else {
            let hex = String(storage, radix: 16)
            let minHexDigits = String(hex.drop { $0 == "0" })
            value = "0x" + minHexDigits
        }
        return value
    }
}

extension EthRpc1 {
    public struct Data {
        public var storage: Foundation.Data

        public init() {
            self.init(storage: .init())
        }

        public init(storage: Foundation.Data) {
            self.storage = storage
        }
    }
}

extension EthRpc1.Data: Codable {
    //    A Data value MUST be hex-encoded.
    //    A Data value MUST be “0x”-prefixed.
    //    A Data value MUST be expressed using two hex digits per byte.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var string = try container.decode(String.self)

        guard string.hasPrefix("0x") else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Data value MUST be 0x-prefixed",
                                      underlyingError: nil)
            )
        }

        string.removeFirst(2)

        guard string.count % 2 == 0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Data value MUST  be expressed using two hex digits per byte.",
                                      underlyingError: nil)
            )
        }

        let hexDigitsPerByte = 2
        let bytes = try stride(from: 0, to: string.count, by: hexDigitsPerByte).map { offset -> UInt8 in
            let startIndex = string.index(string.startIndex, offsetBy: offset)
            let endIndex = string.index(startIndex, offsetBy: hexDigitsPerByte)
            let substring = string[startIndex..<endIndex]
            guard let byte = UInt8(substring, radix: 16) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Data value MUST be hex-encoded",
                                          underlyingError: nil)
                )
            }
            return byte
        }

        self.storage = Data(bytes)
    }

    public func encode(to encoder: Encoder) throws {
        let value = hex
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public var hex: String {
        let value = "0x" + storage.compactMap { String(format: "%02x", Int($0)) }.joined()
        return value
    }
}

extension EthRpc1.Data: CustomStringConvertible {
    public var description: String {
        "0x" + storage.compactMap { String(format: "%02x", Int($0)) }.joined()
    }
}

extension EthRpc1 {
    public enum BlockTag: String, Codable {
        case latest
        case earliest
        case pending
    }
}

extension EthRpc1 {
    public struct BlockNumberIdentifier: Codable {
        public var blockNumber: Quantity<Sol.UInt256>
        public init(blockNumber: EthRpc1.Quantity<Sol.UInt256>) {
            self.blockNumber = blockNumber
        }
    }
    public struct BlockHashIdentifier: Codable {
        public var blockHash: Data
        public var requireCanonical: Bool? = false
        public init(blockHash: EthRpc1.Data, requireCanonical: Bool? = false) {
            self.blockHash = blockHash
            self.requireCanonical = requireCanonical
        }
    }
}

extension EthRpc1 {
    public enum BlockSpecifier: Codable {
        case number(Quantity<Sol.UInt256>)
        case tag(BlockTag)
        case numberId(BlockNumberIdentifier)
        case hashId(BlockHashIdentifier)
    }
}

extension EthRpc1.BlockSpecifier {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = (try? container.decode(EthRpc1.Quantity<Sol.UInt256>.self)) {
            self = .number(value)
        }
        else if let value = (try? container.decode(EthRpc1.BlockTag.self)) {
            self = .tag(value)
        }
        else if let value = (try? container.decode(EthRpc1.BlockNumberIdentifier.self)) {
            self = .numberId(value)
        }
        else if let value = (try? container.decode(EthRpc1.BlockHashIdentifier.self)) {
            self = .hashId(value)
        }
        else {
            throw DecodingError.typeMismatch(
                type(of: self),
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown block specifier",
                    underlyingError: nil)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let value):
            try container.encode(value)
        case .tag(let value):
            try container.encode(value)
        case .numberId(let value):
            try container.encode(value)
        case .hashId(let value):
            try container.encode(value)
        }
    }
}

extension Sol.Address {
    var ethRpcData: EthRpc1.Data {
        let encoded32bytes = self.encode()
        let bytes = encoded32bytes.dropFirst(encoded32bytes.count - self.storage.self.bitWidth / 8)
        return EthRpc1.Data(storage: bytes)
    }
}

extension EthRpc1.Data {
    public init(_ value: Sol.Address) {
        let abiEncoded = value.encode()
        let byteCount = value.storage.self.bitWidth / 8
        let bytes = abiEncoded.suffix(byteCount)
        self.init(storage: bytes)
    }

    public init(_ value: Sol.Bytes) {
        self.init(storage: value.storage)
    }

    public init<T>(_ value: T) where T: SolFixedBytes {
        self.init(storage: value.storage)
    }

    public init(_ value: Eth.Hash) {
        self.init(value.storage)
    }
}


// TODO: MOVE!
extension Sol.UInt64: RlpInteger {}
extension Sol.UInt256: RlpInteger {}
extension Sol.UInt160: RlpInteger {}

extension Sol.Bytes: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        storage.encode(using: coder)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        let result = try storage.decode(value: value, coder: coder) as! Data
        return Self(storage: result)
    }
}

extension SolFixedBytes where Self: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        storage.encode(using: coder)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        let result = try storage.decode(value: value, coder: coder) as! Data
        return Self(storage: result)
    }
}
extension Sol.Bytes32: RlpCodable {}

extension Sol.Address: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        storage.encode(using: coder)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        let result = try storage.decode(value: value, coder: coder) as! Sol.UInt160
        return Self(storage: result)
    }
}

extension Sol.Address: CustomStringConvertible {
    public var description: String {
        EthRpc1.Data(self).description
    }
}

// [nonce, gasPrice, gasLimit, to, value, data, v, r, s]
public enum Eth {
    public struct TransactionLegacy {
        // affects hashing per EIP-155
        public var chainId: Sol.UInt256? = nil

        public var from: Sol.Address? = nil
        public var to: Sol.Address = 0
        public var value: Sol.UInt256 = 0
        public var data: Sol.Bytes = .init()
        public var nonce: Sol.UInt64 = 0

        public var fee: FeeLegacy = .init()

        public var hash: Hash? = nil
        public var signature: SignatureLegacy? = nil
        public var locationInBlock: BlockLocation? = nil

        public init(chainId: Sol.UInt256? = nil, from: Sol.Address? = nil, to: Sol.Address = 0, value: Sol.UInt256 = 0, data: Sol.Bytes = .init(), nonce: Sol.UInt64 = 0, fee: Eth.FeeLegacy = .init(), hash: Eth.Hash? = nil, signature: Eth.SignatureLegacy? = nil, locationInBlock: Eth.BlockLocation? = nil) {
            self.chainId = chainId
            self.from = from
            self.to = to
            self.value = value
            self.data = data
            self.nonce = nonce
            self.fee = fee
            self.hash = hash
            self.signature = signature
            self.locationInBlock = locationInBlock
        }
    }

    public struct FeeLegacy {
        public var gas: Sol.UInt64? = nil
        public var gasPrice: Sol.UInt256? = nil

        public init(gas: Sol.UInt64? = nil, gasPrice: Sol.UInt256? = nil) {
            self.gas = gas
            self.gasPrice = gasPrice
        }
    }

    public struct SignatureLegacy {
        public var v: Sol.UInt256
        public var r: Sol.UInt256
        public var s: Sol.UInt256

        // requires:
        // v = {0, 1}
        // r, s are from the secp256k1 signature
        public init(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256, chainId: Sol.UInt256? = nil) {
            if v < 2 {
                // EIP-155
                // If you do, then the v of the signature MUST be set to {0,1} + CHAIN_ID * 2 + 35
                // otherwise then v continues to be set to {0,1} + 27 as previously.
                if let chainId = chainId {
                    self.v = v + chainId * 2 + 35
                } else {
                    self.v = v + 27
                }
            } else {
                self.v = v
            }
            self.r = r
            self.s = s
        }
    }


    public struct TransactionEip2930 {
        public var type: Sol.UInt64 = 0x01

        public var chainId: Sol.UInt256 = 1

        public var from: Sol.Address? = nil
        public var to: Sol.Address = 0
        public var value: Sol.UInt256 = 0
        public var data: Sol.Bytes = .init()
        public var nonce: Sol.UInt64 = 0

        public var fee: Fee2930 = .init()

        public var hash: Hash? = nil
        public var signature: Signature? = nil
        public var locationInBlock: BlockLocation? = nil

        public init(type: Sol.UInt64 = 0x01, chainId: Sol.UInt256 = 1, from: Sol.Address? = nil, to: Sol.Address = 0, value: Sol.UInt256 = 0, data: Sol.Bytes = .init(), nonce: Sol.UInt64 = 0, fee: Eth.Fee2930 = .init(), hash: Eth.Hash? = nil, signature: Eth.Signature? = nil, locationInBlock: Eth.BlockLocation? = nil) {
            self.type = type
            self.chainId = chainId
            self.from = from
            self.to = to
            self.value = value
            self.data = data
            self.nonce = nonce
            self.fee = fee
            self.hash = hash
            self.signature = signature
            self.locationInBlock = locationInBlock
        }
    }

    public struct Fee2930 {
        public var gas: Sol.UInt64? = nil
        public var gasPrice: Sol.UInt256? = nil
        public var accessList: AccessList = .init()

        public init(gas: Sol.UInt64? = nil, gasPrice: Sol.UInt256? = nil, accessList: Eth.AccessList = .init()) {
            self.gas = gas
            self.gasPrice = gasPrice
            self.accessList = accessList
        }
    }

    public struct TransactionEip1559 {
        public var type: Sol.UInt64 = 0x02

        public var chainId: Sol.UInt256 = 1

        public var from: Sol.Address? = nil
        public var to: Sol.Address = 0
        public var value: Sol.UInt256 = 0
        public var data: Sol.Bytes = .init()
        public var nonce: Sol.UInt64 = 0

        public var fee: Fee1559 = .init()

        public var hash: Hash? = nil

        public var signature: Signature? = nil

        public var locationInBlock: BlockLocation? = nil

        public init(
            type: Sol.UInt64 = 0x02,
            chainId: Sol.UInt256 = 1,
            from: Sol.Address? = nil,
            to: Sol.Address = 0,
            value: Sol.UInt256 = 0,
            data: Sol.Bytes = .init(),
            nonce: Sol.UInt64 = 0,
            fee: Eth.Fee1559 = .init(),
            hash: Hash? = nil,
            signature: Eth.Signature? = nil,
            locationInBlock: Eth.BlockLocation? = nil
        ) {
            self.type = type
            self.chainId = chainId
            self.from = from
            self.to = to
            self.value = value
            self.data = data
            self.nonce = nonce
            self.fee = fee
            self.hash = hash
            self.signature = signature
            self.locationInBlock = locationInBlock
        }

        public init() {
            self.init(
                type: 0x02,
                chainId: 1,
                from: nil,
                to: 0,
                value: 0,
                data: Sol.Bytes(),
                nonce: 0,
                fee: Eth.Fee1559(),
                hash: nil,
                signature: nil,
                locationInBlock: nil
            )
        }
    }

    public struct Fee1559 {
        public var gas: Sol.UInt64? = nil
        public var maxFeePerGas: Sol.UInt256? = nil
        public var maxPriorityFee: Sol.UInt256? = nil
        public var accessList: AccessList = .init()

        public init(gas: Sol.UInt64? = nil, maxFeePerGas: Sol.UInt256? = nil, maxPriorityFee: Sol.UInt256? = nil, accessList: Eth.AccessList = .init()) {
            self.gas = gas
            self.maxFeePerGas = maxFeePerGas
            self.maxPriorityFee = maxPriorityFee
            self.accessList = accessList
        }
    }

    public struct BlockLocation {
        public var blockHash: Sol.Bytes32 = .init()
        public var blockNumber: Sol.UInt256 = 0
        public var transactionIndex: Sol.UInt64 = 0

        public init(blockHash: Sol.Bytes32 = .init(), blockNumber: Sol.UInt256 = 0, transactionIndex: Sol.UInt64 = 0) {
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.transactionIndex = transactionIndex
        }
    }

    public struct Signature {
        public var yParity: Sol.UInt256 = 0
        public var r: Sol.UInt256 = 0
        public var s: Sol.UInt256 = 0

        public init(yParity: Sol.UInt256 = 0, r: Sol.UInt256 = 0, s: Sol.UInt256 = 0) {
            self.yParity = yParity
            self.r = r
            self.s = s
        }
    }

    public struct AccessList {
        public var elements: [AccessListElement] = []
        public init(elements: [Eth.AccessListElement] = []) {
            self.elements = elements
        }

        public init() {
            self.elements = []
        }
    }

    public struct AccessListElement {
        public var address: Sol.Address = 0
        public var storageKeys: [Sol.Bytes32] = []
        public init(address: Sol.Address = 0, storageKeys: [Sol.Bytes32] = []) {
            self.address = address
            self.storageKeys = storageKeys
        }

        public init() {
            self.address = 0
            self.storageKeys = []
        }
    }

    public struct Hash {
        public var storage: Sol.Bytes32

        public init(_ value: Sol.Bytes32) {
            self.storage = value
        }

        public init(_ value: Foundation.Data) {
            self.storage = Sol.Bytes32(storage: value)
        }

        public init() {
            self.storage = Sol.Bytes32()
        }
    }
}

extension Eth.AccessListElement: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        let array = [address, storageKeys as [RlpCodable]] as [RlpCodable]
        let result = coder.encode(array)
        return result
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        guard let array = value as? [RlpCodable], array.count == 2 else {
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }

        let address = try self.address.decode(value: array[0], coder: coder)
        let storageKeys = try (self.storageKeys as [RlpCodable]).decode(value: array[1], coder: coder)

        return Self(
            address: address as! Sol.Address,
            storageKeys: storageKeys as! [Sol.Bytes32]
        )
    }
}

extension Eth.AccessList: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        let list: [RlpCodable] = elements.map { element -> RlpCodable in
            element.encode(using: coder)
        }
        let result = coder.encode(list)
        return result
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        let list = try (self.elements as [RlpCodable]).decode(value: value, coder: coder)
        return Self(elements: list as! [Eth.AccessListElement])
    }
}

// TODO: extract to file?
import CryptoSwift

public protocol EthSignable {
    func preImageForSigning() -> Data
    func hashForSigning() -> Eth.Hash
}

extension EthSignable {
    public func hashForSigning() -> Eth.Hash {
        let hash = Data(SHA3(variant: .keccak256).calculate(for: preImageForSigning().bytes))
        return Eth.Hash(hash)
    }
}

public protocol EthRawTransaction {
    func rawTransaction() -> EthRpc1.Data
    func txHash() -> Eth.Hash
}

extension EthRawTransaction {
    public func txHash() -> Eth.Hash {
        let hash = Data(SHA3(variant: .keccak256).calculate(for: rawTransaction().storage.bytes))
        return Eth.Hash(hash)
    }
}

public protocol EthTransaction: EthSignable, EthRawTransaction {
    var from: Sol.Address? { get }
    var hash: Eth.Hash? { get set }
    var to: Sol.Address { get }
    var value: Sol.UInt256 { get }
    var data: Sol.Bytes { get }

    // derived from the fee and value
    var requiredBalance: Sol.UInt256 { get }

    var totalFee: Sol.UInt256 { get }

    mutating func update(gas: Sol.UInt64, transactionCount: Sol.UInt64, baseFee: Sol.UInt256)
    mutating func updateSignature(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256)
    mutating func removeFee()
}

extension Eth.TransactionEip1559: EthSignable {
    // The signature_y_parity, signature_r, signature_s elements of this transactin represent a
    // secp256k1 signature over
    // keccak256(0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list]))

    public func preImageForSigning() -> Data {
        let array: [RlpCodable] = [
            chainId,
            nonce,
            fee.maxPriorityFee ?? 0,
            fee.maxFeePerGas ?? 0,
            fee.gas ?? 0,
            to,
            value,
            data,
            fee.accessList
        ]
        let rlpTransaction = RlpCoder().encode(array)
        let preImage = Data([UInt8(type)]) + rlpTransaction
        return preImage
    }
}

extension Eth.TransactionEip1559: EthTransaction {
    public mutating func update(gas: Sol.UInt64, transactionCount: Sol.UInt64, baseFee: Sol.UInt256) {
        nonce = transactionCount
        fee.gas = gas
        // Polygon only sets 'priority' fee, the baseFee is 0
        if self.chainId == 137 {
            fee.maxPriorityFee = baseFee
            fee.maxFeePerGas = baseFee
        } else {
            fee.maxFeePerGas = (fee.maxPriorityFee ?? 0) + baseFee
        }
    }

    public mutating func updateSignature(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256) {
        self.signature = Eth.Signature(yParity: v, r: r, s: s)
    }

    public var requiredBalance: Sol.UInt256 {
        totalFee + value
    }

    public var totalFee: Sol.UInt256 {
        Sol.UInt256(fee.gas ?? 0) * (fee.maxFeePerGas ?? 0)
    }

    public mutating func removeFee() {
        fee = .init()
    }
}

extension Eth.TransactionEip1559: EthRawTransaction {
    //        // rlp-encode transaction items
    //        let rlpTransaction = RlpCoder().encode([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list as [RlpCodable]])

    public func rawTransaction() -> EthRpc1.Data {
        let signature = self.signature ?? Eth.Signature(yParity: 0, r: 0, s: 0)
        let array: [RlpCodable] = [
            chainId,
            nonce,
            fee.maxPriorityFee ?? 0,
            fee.maxFeePerGas ?? 0,
            fee.gas ?? 0,
            to,
            value,
            data,
            fee.accessList,
            signature.yParity,
            signature.r,
            signature.s
        ]
        let rlpEncoded = RlpCoder().encode(array)
        let result = Data([UInt8(type)]) + rlpEncoded
        return EthRpc1.Data(storage: result)
    }
}

extension EthRpc1.eth_estimateGas {
    public init(_ tx: EthTransaction) {
        self.init(transaction: EthRpc1.Transaction(tx))
    }
}

extension EthRpc1.Transaction {
    public init(_ tx: EthTransaction) {
        switch tx {
        case let eip1559 as Eth.TransactionEip1559:
            self = .eip1559(EthRpc1.Transaction1559(eip1559))
        case let eip2930 as Eth.TransactionEip2930:
            self = .eip2930(EthRpc1.Transaction2930(eip2930))
        case let legacy as Eth.TransactionLegacy:
            self = .legacy(EthRpc1.TransactionLegacy(legacy))
        default:
            fatalError("Not implemented")
        }
    }
}

extension EthRpc1.eth_estimateGasLegacyApi {
    public init(_ tx: EthTransaction) {
        self.init(transaction: EthRpc1.EstimateGasLegacyTransaction(tx))
    }
}

extension EthRpc1.EstimateGasLegacyTransaction {
    public init(_ tx: EthTransaction) {
        switch tx {
        case let eip1559 as Eth.TransactionEip1559:
            self.init(eip1559)
        case let eip2930 as Eth.TransactionEip2930:
            self.init(eip2930)
        case let legacy as Eth.TransactionLegacy:
            self.init(legacy)
        default:
            fatalError("Not implemented")
        }
    }

    public var ethTransaction: EthTransaction {
        if let type = type?.storage, type == 0x01 {
            return Eth.TransactionEip2930(
                type: type,
                chainId: 0,
                from: self.from.map(\.storage).flatMap(Sol.Address.init(maybeData:)),
                to: self.to.map(\.storage).flatMap(Sol.Address.init(maybeData:)) ?? 0,
                value: self.value.storage,
                data: Sol.Bytes(storage: self.data.storage),
                nonce: self.nonce?.storage ?? 0,
                fee: Eth.Fee2930(gas: self.gas?.storage, gasPrice: self.gasPrice?.storage, accessList: Eth.AccessList()),
                hash: nil,
                signature: nil,
                locationInBlock: nil
            )
        } else if let type = type?.storage, type == 0x02 {
            return Eth.TransactionEip1559(
                type: type,
                chainId: 0,
                from: self.from.map(\.storage).flatMap(Sol.Address.init(maybeData:)),
                to: self.to.map(\.storage).flatMap(Sol.Address.init(maybeData:)) ?? 0,
                value: self.value.storage,
                data: Sol.Bytes(storage: self.data.storage),
                nonce: self.nonce?.storage ?? 0,
                fee: Eth.Fee1559(gas: self.gas?.storage, maxFeePerGas: self.maxFeePerGas?.storage, maxPriorityFee: self.maxPriorityFeePerGas?.storage, accessList: Eth.AccessList()),
                hash: nil,
                signature: nil,
                locationInBlock: nil)
        } else {
            return Eth.TransactionLegacy(
                chainId: nil,
                from: self.from.map(\.storage).flatMap(Sol.Address.init(maybeData:)),
                to: self.to.map(\.storage).flatMap(Sol.Address.init(maybeData:)) ?? 0,
                value: self.value.storage,
                data: Sol.Bytes(storage: self.data.storage),
                nonce: self.nonce?.storage ?? 0,
                fee: Eth.FeeLegacy(gas: self.gas?.storage, gasPrice: self.gasPrice?.storage),
                hash: nil,
                signature: nil,
                locationInBlock: nil)
        }
    }
}

extension EthRpc1.Transaction1559 {
    public init(_ tx: Eth.TransactionEip1559) {
        self.init(
            type: EthRpc1.Quantity<Sol.UInt64>(tx.type),
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            maxPriorityFeePerGas: tx.fee.maxPriorityFee.map(EthRpc1.Quantity<Sol.UInt256>.init),
            maxFeePerGas: tx.fee.maxFeePerGas.map(EthRpc1.Quantity<Sol.UInt256>.init),
            accessList: [EthRpc1.AccessListEntry](tx.fee.accessList),
            chainId: EthRpc1.Quantity<Sol.UInt256>(tx.chainId),
            from: tx.from.map { EthRpc1.Data($0) },
            blockHash: (tx.locationInBlock?.blockHash).map { EthRpc1.Data($0) },
            blockNumber: (tx.locationInBlock?.blockNumber).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            hash: tx.hash.map { EthRpc1.Data($0) },
            transactionIndex: (tx.locationInBlock?.transactionIndex).map { EthRpc1.Quantity<Sol.UInt64>($0) },
            yParity: (tx.signature?.yParity).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            r: (tx.signature?.r).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            s: (tx.signature?.s).map { EthRpc1.Quantity<Sol.UInt256>($0) }
        )
    }
}


extension EthRpc1.EstimateGasLegacyTransaction {
    public init(_ tx: Eth.TransactionEip1559) {
        self.init(
            type: EthRpc1.Quantity<Sol.UInt64>(tx.type),
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            gasPrice: nil,
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            maxPriorityFeePerGas: tx.fee.maxPriorityFee.map(EthRpc1.Quantity<Sol.UInt256>.init),
            maxFeePerGas: tx.fee.maxFeePerGas.map(EthRpc1.Quantity<Sol.UInt256>.init),
            from: tx.from.map(EthRpc1.Data.init)
        )
    }
}

// MARK: Eip2930
extension Eth.TransactionEip2930: EthSignable {
    public func preImageForSigning() -> Data {
        let array: [RlpCodable] = [
            chainId,
            nonce,
            fee.gasPrice ?? 0,
            fee.gas ?? 0,
            to,
            value,
            data,
            fee.accessList
        ]
        let rlpTransaction = RlpCoder().encode(array)
        let preImage = Data([UInt8(type)]) + rlpTransaction
        return preImage
    }
}

extension Eth.TransactionEip2930: EthRawTransaction {
    public func rawTransaction() -> EthRpc1.Data {
        let signature = self.signature ?? Eth.Signature(yParity: 0, r: 0, s: 0)
        let array: [RlpCodable] = [
            chainId,
            nonce,
            fee.gasPrice ?? 0,
            fee.gas ?? 0,
            to,
            value,
            data,
            fee.accessList,
            signature.yParity,
            signature.r,
            signature.s
        ]
        let rlpEncoded = RlpCoder().encode(array)
        let result = Data([UInt8(type)]) + rlpEncoded
        return EthRpc1.Data(storage: result)
    }
}

extension Eth.TransactionEip2930: EthTransaction {
    public mutating func update(gas: Sol.UInt64, transactionCount: Sol.UInt64, baseFee: Sol.UInt256) {
        nonce = transactionCount
        fee.gas = gas
        fee.gasPrice = baseFee
    }

    public mutating func updateSignature(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256) {
        self.signature = Eth.Signature(yParity: v, r: r, s: s)
    }

    public var requiredBalance: Sol.UInt256 {
        totalFee + value
    }

    public var totalFee: Sol.UInt256 {
        Sol.UInt256(fee.gas ?? 0) * (fee.gasPrice ?? 0)
    }

    public mutating func removeFee() {
        fee = .init()
    }
}

extension EthRpc1.Transaction {
    public var ethTransaction: EthTransaction? {
        switch self {
        case .legacy(let tx):
            return Eth.TransactionLegacy(tx)
        case .eip1559(let tx):
            return Eth.TransactionEip1559(tx)
        case .eip2930(let tx):
            return Eth.TransactionEip2930(tx)
        case .unknown:
            return nil
        }
    }
}

extension Eth.TransactionLegacy {
    public init(_ tx: EthRpc1.TransactionLegacy) {
        self.init(
            chainId: tx.chainId?.storage,
            from: (tx.from?.storage).flatMap(Sol.Address.init(exactly:)),
            to: (tx.to?.storage).flatMap(Sol.Address.init(exactly:)) ?? 0,
            value: tx.value.storage,
            data: Sol.Bytes(exactly: tx.data.storage) ?? Sol.Bytes(),
            nonce: tx.nonce?.storage ?? 0,
            fee: Eth.FeeLegacy(gas: tx.gas?.storage, gasPrice: tx.gasPrice?.storage),
            hash: (tx.hash?.storage).map(Eth.Hash.init),
            signature: Eth.SignatureLegacy(v: tx.v?.storage, r: tx.r?.storage, s: tx.s?.storage),
            locationInBlock: Eth.BlockLocation(
                blockHash: (tx.blockHash?.storage).flatMap(Sol.Bytes32.init(exactly:)),
                blockNumber: tx.blockNumber?.storage,
                transactionIndex: tx.transactionIndex?.storage
            )
        )
    }
}

extension Eth.TransactionEip1559 {
    public init(_ tx: EthRpc1.Transaction1559) {
        self.init(
            type: tx.type.storage,
            chainId: tx.chainId.storage,
            from: (tx.from?.storage).flatMap(Sol.Address.init(exactly:)),
            to: (tx.to?.storage).flatMap(Sol.Address.init(exactly:)) ?? 0,
            value: tx.value.storage,
            data: Sol.Bytes(exactly: tx.data.storage) ?? Sol.Bytes(),
            nonce: tx.nonce?.storage ?? 0,
            fee: Eth.Fee1559(gas: tx.gas?.storage, maxFeePerGas: tx.maxFeePerGas?.storage, maxPriorityFee: tx.maxPriorityFeePerGas?.storage, accessList: Eth.AccessList(tx.accessList)),
            hash: (tx.hash?.storage).map(Eth.Hash.init),
            signature: Eth.Signature(yParity: tx.yParity?.storage, r: tx.r?.storage, s: tx.s?.storage),
            locationInBlock: Eth.BlockLocation(
                blockHash: (tx.blockHash?.storage).flatMap(Sol.Bytes32.init(exactly:)),
                blockNumber: tx.blockNumber?.storage,
                transactionIndex: tx.transactionIndex?.storage
            )
        )
    }
}

extension Eth.TransactionEip2930 {
    public init(_ tx: EthRpc1.Transaction2930) {
        self.init(
            type: tx.type.storage,
            chainId: tx.chainId.storage,
            from: (tx.from?.storage).flatMap(Sol.Address.init(exactly:)),
            to: (tx.to?.storage).flatMap(Sol.Address.init(exactly:)) ?? 0,
            value: tx.value.storage,
            data: Sol.Bytes(exactly: tx.data.storage) ?? Sol.Bytes(),
            nonce: tx.nonce?.storage ?? 0,
            fee: Eth.Fee2930(gas: tx.gas?.storage, gasPrice: tx.gasPrice?.storage, accessList: Eth.AccessList(tx.accessList)),
            hash: (tx.hash?.storage).map(Eth.Hash.init),
            signature: Eth.Signature(yParity: tx.yParity?.storage, r: tx.r?.storage, s: tx.s?.storage),
            locationInBlock: Eth.BlockLocation(
                blockHash: (tx.blockHash?.storage).flatMap(Sol.Bytes32.init(exactly:)),
                blockNumber: tx.blockNumber?.storage,
                transactionIndex: tx.transactionIndex?.storage
            )
        )
    }
}

extension Eth.AccessList {
    public init(_ values: [EthRpc1.AccessListEntry]) {
        elements = values.map(Eth.AccessListElement.init)
    }
}

extension Eth.AccessListElement {
    public init(_ value: EthRpc1.AccessListEntry) {
        address = (value.address?.storage).flatMap(Sol.Address.init(exactly:)) ?? 0
        storageKeys = (value.storageKeys ?? []).map(\.storage).compactMap(Sol.Bytes32.init(exactly:))
    }
}

extension Eth.Signature {
    public init?(yParity: Sol.UInt256?, r: Sol.UInt256?, s: Sol.UInt256?) {
        guard let yParity = yParity, let r = r, let s = s else {
            return nil
        }
        self.init(yParity: yParity, r: r, s: s)
    }
}

extension Eth.SignatureLegacy {
    public init?(v: Sol.UInt256?, r: Sol.UInt256?, s: Sol.UInt256?, chainId: Sol.UInt256? = nil) {
        guard let v = v, let r = r, let s = s else {
            return nil
        }
        self.init(v: v, r: r, s: s, chainId: chainId)
    }
}

extension Eth.BlockLocation {
    public init?(blockHash: Sol.Bytes32?, blockNumber: Sol.UInt256?, transactionIndex: Sol.UInt64?) {
        guard let blockHash = blockHash, let blockNumber = blockNumber, let index = transactionIndex else {
            return nil
        }
        self.init(blockHash: blockHash, blockNumber: blockNumber, transactionIndex: index)
    }
}


extension EthRpc1.Transaction2930 {
    public init(_ tx: Eth.TransactionEip2930) {
        self.init(
            type: EthRpc1.Quantity<Sol.UInt64>(tx.type),
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            gasPrice: tx.fee.gasPrice.map(EthRpc1.Quantity<Sol.UInt256>.init),
            accessList: [EthRpc1.AccessListEntry](tx.fee.accessList),
            chainId: EthRpc1.Quantity<Sol.UInt256>(tx.chainId),
            from: tx.from.map { EthRpc1.Data($0) },
            blockHash: (tx.locationInBlock?.blockHash).map { EthRpc1.Data($0) },
            blockNumber: (tx.locationInBlock?.blockNumber).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            hash: tx.hash.map { EthRpc1.Data($0) },
            transactionIndex: (tx.locationInBlock?.transactionIndex).map { EthRpc1.Quantity<Sol.UInt64>($0) },
            yParity: (tx.signature?.yParity).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            r: (tx.signature?.r).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            s: (tx.signature?.s).map { EthRpc1.Quantity<Sol.UInt256>($0) }
        )
    }
}

extension EthRpc1.EstimateGasLegacyTransaction {
    public init(_ tx: Eth.TransactionEip2930) {
        self.init(
            type: EthRpc1.Quantity<Sol.UInt64>(tx.type),
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            gasPrice: tx.fee.gasPrice.map(EthRpc1.Quantity<Sol.UInt256>.init),
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil,
            from: tx.from.map { EthRpc1.Data($0) }
        )
    }
}


// MARK: Legacy
extension Eth.TransactionLegacy: EthSignable {
    public func preImageForSigning() -> Data {
        let array: [RlpCodable]
        if let chainId = chainId {
            // (nonce, gasprice, startgas, to, value, data, chainid, 0, 0)
            array = [
                nonce,
                fee.gasPrice ?? 0,
                fee.gas ?? 0,
                to,
                value,
                data,
                chainId,
                Sol.UInt256(0),
                Sol.UInt256(0)
            ]
        } else {
            // (nonce, gasprice, startgas, to, value, data)
            array = [
                nonce,
                fee.gasPrice ?? 0,
                fee.gas ?? 0,
                to,
                value,
                data
            ]
        }
        let rlpTransaction = RlpCoder().encode(array)
        // eip-2718
        // rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
        let preImage = rlpTransaction
        return preImage
    }
}

extension Eth.TransactionLegacy: EthRawTransaction {
    public func rawTransaction() -> EthRpc1.Data {
        // If you do, then the v of the signature MUST be set to {0,1} + CHAIN_ID * 2 + 35
        // otherwise then v continues to be set to {0,1} + 27 as previously.
        let signature = self.signature ?? Eth.SignatureLegacy(v: 0, r: 0, s: 0, chainId: chainId)
        let array: [RlpCodable] = [
            nonce,
            fee.gasPrice ?? 0,
            fee.gas ?? 0,
            to,
            value,
            data,
            signature.v,
            signature.r,
            signature.s
        ]
        let rlpEncoded = RlpCoder().encode(array)
        // eip-2718
        // rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
        let result = rlpEncoded
        return EthRpc1.Data(storage: result)
    }
}

extension Eth.TransactionLegacy: EthTransaction {
    public mutating func update(gas: Sol.UInt64, transactionCount: Sol.UInt64, baseFee: Sol.UInt256) {
        nonce = transactionCount
        fee.gas = gas
        fee.gasPrice = baseFee
    }

    public mutating func updateSignature(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256) {
        self.signature = Eth.SignatureLegacy(v: v, r: r, s: s, chainId: chainId)
    }

    public var requiredBalance: Sol.UInt256 {
        totalFee + value
    }

    public var totalFee: Sol.UInt256 {
        Sol.UInt256(fee.gas ?? 0) * (fee.gasPrice ?? 0)
    }

    public mutating func removeFee() {
        fee = .init()
    }
}

extension EthRpc1.TransactionLegacy {
    public init(_ tx: Eth.TransactionLegacy) {
        self.init(
            // type is the 1st byte of the encoded rlp transaction
            // rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
            type: EthRpc1.Quantity<Sol.UInt64>(Sol.UInt64(tx.rawTransaction().storage[0])),
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            gasPrice: tx.fee.gasPrice.map(EthRpc1.Quantity<Sol.UInt256>.init),
            chainId: EthRpc1.Quantity<Sol.UInt256>(tx.chainId ?? 0),
            from: tx.from.map { EthRpc1.Data($0) },
            blockHash: (tx.locationInBlock?.blockHash).map { EthRpc1.Data($0) },
            blockNumber: (tx.locationInBlock?.blockNumber).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            hash: tx.hash.map { EthRpc1.Data($0) },
            transactionIndex: (tx.locationInBlock?.transactionIndex).map { EthRpc1.Quantity<Sol.UInt64>($0) },
            v: (tx.signature?.v).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            r: (tx.signature?.r).map { EthRpc1.Quantity<Sol.UInt256>($0) },
            s: (tx.signature?.s).map { EthRpc1.Quantity<Sol.UInt256>($0) }
        )
    }
}

extension EthRpc1.EstimateGasLegacyTransaction {
    public init(_ tx: Eth.TransactionLegacy) {
        self.init(
            type: nil,
            nonce: EthRpc1.Quantity<Sol.UInt64>(tx.nonce),
            to: EthRpc1.Data(tx.to),
            gas: tx.fee.gas.map(EthRpc1.Quantity<Sol.UInt64>.init),
            gasPrice: tx.fee.gasPrice.map(EthRpc1.Quantity<Sol.UInt256>.init),
            value: EthRpc1.Quantity<Sol.UInt256>(tx.value),
            data: EthRpc1.Data(tx.data),
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil,
            from: tx.from.map { EthRpc1.Data($0) }
        )
    }
}


extension Array where Element == EthRpc1.AccessListEntry {
    public init(_ list: Eth.AccessList) {
        self = list.elements.map({ element in
            EthRpc1.AccessListEntry(
                address: EthRpc1.Data(element.address),
                storageKeys: element.storageKeys.map { storageKey in
                    EthRpc1.Data(storageKey)
                }
            )
        })
    }
}

public protocol EthUnit {
    var symbol: String { get }

    init(symbol: String)
}

public protocol EthUnitConverter {
    // returns value in terms of a base unit of its dimension
    func baseUnitValue(from value: Sol.UInt256) -> Sol.UInt256
    // returns the base unit in terms of the value
    func value(from baseUnitValue: Sol.UInt256) -> Sol.UInt256
}

public protocol EthDimension: EthUnit {
    init(symbol: String, converter: EthUnitConverter)
    var converter: EthUnitConverter { get }
    static var baseUnit: Self { get }
}

extension Eth {
    public struct Amount<UnitType> where UnitType: EthUnit {
        public var value: Sol.UInt256
        public var unit: UnitType

        public init(value: Sol.UInt256, unit: UnitType) {
            self.value = value
            self.unit = unit
        }
    }
}

extension Eth.Amount where UnitType: EthDimension {
    public mutating func convert(to otherUnit: UnitType) {
        // convert self.value from self.unit to otherUnit
        // convert self.value to base unit
        let valueInBaseUnits = self.unit.converter.baseUnitValue(from: self.value)
        // convert base unit to other unit
        let valueInOtherUnits = otherUnit.converter.value(from: valueInBaseUnits)
        self.value = valueInOtherUnits
        self.unit = otherUnit
    }

    public func converted(to otherUnit: UnitType) -> Eth.Amount<UnitType> {
        // return new amount with value converted from self.unit to the other unit
        var otherAmount = self
        otherAmount.convert(to: otherUnit)
        return otherAmount
    }
}

extension Eth {
    public struct UnitConverterLinear: EthUnitConverter {
        // a
        public let coefficient: Sol.UInt256
        // b
        public let constant: Sol.UInt256

        public init(coefficient: Sol.UInt256, constant: Sol.UInt256 = 0) {
            self.coefficient = coefficient
            self.constant = constant
        }

        // y = ax + b
        public func baseUnitValue(from value: Sol.UInt256) -> Sol.UInt256 {
            coefficient * value + constant
        }

        // x = (y - b) / a
        public func value(from baseUnitValue: Sol.UInt256) -> Sol.UInt256 {
            (baseUnitValue - constant) / coefficient
        }
    }
}

extension Eth {
    public struct Unit: EthDimension {
        public var symbol: String
        public var converter: EthUnitConverter

        public init(symbol: String) {
            self.symbol = symbol
            self.converter = UnitConverterLinear(coefficient: 1)
        }

        public init(symbol: String, converter: EthUnitConverter) {
            self.symbol = symbol
            self.converter = converter
        }

        public static let baseUnit: Eth.Unit = wei

        // Reference: https://www.languagesandnumbers.com/articles/en/ethereum-ether-units/

        public static let wei = Eth.Unit(symbol: "Wei", converter: UnitConverterLinear(coefficient: 1))
        public static let attoether = Eth.Unit(symbol: "aΞ", converter: kilowei.converter)

        public static let kilowei = Eth.Unit(symbol: "Kwei", converter: UnitConverterLinear(coefficient: 1_000))
        public static let femtoether = Eth.Unit(symbol: "fΞ", converter: kilowei.converter)
        public static let lovelace = Eth.Unit(symbol: "Ada", converter: kilowei.converter)

        public static let megawei = Eth.Unit(symbol: "Mwei", converter: UnitConverterLinear(coefficient: 1_000_000))
        public static let picoether = Eth.Unit(symbol: "pΞ", converter: megawei.converter)
        public static let babbage = Eth.Unit(symbol: "Babbage", converter: megawei.converter)

        public static let gigawei = Eth.Unit(symbol: "Gwei", converter: UnitConverterLinear(coefficient: 1_000_000_000))
        public static let nanoether = Eth.Unit(symbol: "nΞ", converter: gigawei.converter)
        public static let shannon = Eth.Unit(symbol: "Shannon", converter: gigawei.converter)

        public static let terawei = Eth.Unit(symbol: "Twei", converter: UnitConverterLinear(coefficient: 1_000_000_000_000))
        public static let microether = Eth.Unit(symbol: "μΞ", converter: terawei.converter)
        public static let szabo = Eth.Unit(symbol: "Szabo", converter: terawei.converter)

        public static let petawei = Eth.Unit(symbol: "Pwei", converter: UnitConverterLinear(coefficient: 1_000_000_000_000_000))
        public static let milliether = Eth.Unit(symbol: "mΞ", converter: petawei.converter)
        public static let finney = Eth.Unit(symbol: "Finney", converter: petawei.converter)

        public static let exawei = Eth.Unit(symbol: "Ewei", converter: UnitConverterLinear(coefficient: 1_000_000_000_000_000_000))
        public static let ether = Eth.Unit(symbol: "Ξ", converter: exawei.converter)
        public static let buterin = Eth.Unit(symbol: "Buterin", converter: exawei.converter)

        public static let kiloether = Eth.Unit(symbol: "kΞ", converter: UnitConverterLinear(coefficient: "1000000000000000000000"))
        public static let grand = Eth.Unit(symbol: "Grand", converter: kiloether.converter)
        public static let einstein = Eth.Unit(symbol: "Einstein", converter: kiloether.converter)

        public static let megaether = Eth.Unit(symbol: "MΞ", converter: UnitConverterLinear(coefficient: "1000000000000000000000000"))

        public static let gigaether = Eth.Unit(symbol: "GΞ", converter: UnitConverterLinear(coefficient: "1000000000000000000000000000"))

        public static let teraether = Eth.Unit(symbol: "TΞ", converter: UnitConverterLinear(coefficient: "1000000000000000000000000000000"))
    }
}

extension Eth {
    public struct TokenAmount<T> where T: WordUnsignedInteger {
        public var symbol: String
        public var value: T {
            get { storage.storage }
            set { storage.storage = newValue }
        }
        public var decimals: Int {
            get { storage.exponent }
            set { storage.exponent = newValue }
        }
        public var storage: Sol.UnsignedFixedPoint<T>

        public init(value: T, decimals: Int, symbol: String = "") {
            storage = .init(storage: value, exponent: decimals)
            self.symbol = symbol
        }

        public init(value: Sol.UnsignedFixedPoint<T>, symbol: String) {
            storage = value
            self.symbol = symbol
        }
    }
}


import WordInteger

extension Eth.TokenAmount {
    public func converted(to decimals: Int) -> Eth.TokenAmount<T> {
        let diff = self.decimals - decimals
        let powerOf10 = pow(10 as T, abs(diff))
        let value = diff >= 0 ? value * powerOf10 : value / powerOf10
        return .init(value: value, decimals: decimals, symbol: symbol)
    }

    /// converts from string to decimal with each part in the same radix
    /// accepted dot symbols: .,٫ (COMMA, ARABIC DECIMAL SEPARATOR, FULL STOP)
    /// does not recognize thousand separators.
    public init?(_ value: String, radix: Int, decimals: Int) {
        // get suffix
        let parts = value.split(separator: " ").map(String.init)

        let maybeNumber: String
        let symbol: String

        if parts.count == 1 {
            maybeNumber = parts[0]
            symbol = ""
        } else if parts.count == 2 {
            maybeNumber = parts[0]
            symbol = parts[1]
        } else {
            return nil
        }

        if maybeNumber.isEmpty {
            return nil
        }

        let dotSymbol = ".,٫"
        let containsDot = maybeNumber.contains(where: { dotSymbol.contains($0) })

        var (integerPart, fractionalPart) = ("", "")

        // if contains dot - then fractional
        if containsDot {
            let numberParts = maybeNumber.split(whereSeparator: { dotSymbol.contains($0) }).map(String.init)

            if numberParts.isEmpty {
                // only dot inside - not a number
                return nil
            } else if numberParts.count == 1 {
                let isDotInFront = dotSymbol.contains(maybeNumber.first!)

                if isDotInFront {
                    fractionalPart = numberParts[0]
                } else {
                    // dot at the end
                    integerPart = numberParts[0]
                }
            } else if numberParts.count == 2 {
                // dot in the middle
                (integerPart, fractionalPart) = (numberParts[0], numberParts[1])

            } else {
                // multiple dots
                return nil
            }
        } else {
            integerPart = maybeNumber
        }

        if fractionalPart.isEmpty && integerPart.isEmpty {
            return nil
        }

        if fractionalPart.count < decimals {
            fractionalPart = fractionalPart + String(repeating: "0", count: decimals - fractionalPart.count)
        }

        if fractionalPart.count > decimals {
            return nil
        }

        let baseUnitValue = integerPart + fractionalPart
        guard let value = T(baseUnitValue, radix: radix) else {
            return nil
        }

        self.storage = Sol.UnsignedFixedPoint(storage: value, exponent: decimals)
        self.symbol = symbol
    }
}

extension Eth.TokenAmount: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
        hasher.combine(symbol)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.symbol == rhs.symbol else { return false }
        if lhs.decimals == rhs.decimals {
            return lhs.storage == rhs.storage
        } else if lhs.decimals < rhs.decimals {
            return lhs.converted(to: rhs.decimals) == rhs
        } else {
            return rhs.converted(to: lhs.decimals) == lhs
        }
    }
}

extension Eth.TokenAmount: CustomStringConvertible {
    public var description: String {
        let decimalSeparator = Character(Locale.current.decimalSeparator ?? ".")
        var string = String(value, radix: 10)
        if string.count > decimals {
            // more than 1
            string.insert(decimalSeparator, at: string.index(string.endIndex, offsetBy: -decimals))
        } else {
            // less than 1, needs padding
            let padding = decimals - string.count
            string = "0\(decimalSeparator)" + String(repeating: "0", count: padding) + string
        }
        // remove trailing zeroes from fractional part
        while string.hasSuffix("0") {
            string.removeLast()
        }
        // remove trailing decimalSeparator.
        if string.hasSuffix("\(decimalSeparator)") {
            string.removeLast()
        }
        let result = string + (symbol.isEmpty ? "" : (" " + symbol))
        return result
    }
}

extension String {
    public init<T>(_ value: Eth.TokenAmount<T>) {
        self = value.description
    }
}
