//
//  EthRpc1.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import Foundation
import JsonRpc2

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
    }

    public struct TransactionLegacy: Codable {
        /// type according to EIP-2718
        ///
        /// Must be in range [0xc0, 0xfe]
        public var type: String

        public var nonce: String

        /// to address
        public var to: String?

        /// gas limit
        public var gas: String

        public var value: String

        /// input data
        public var input: String

        /// The gas price willing to be paid by the sender in wei
        public var gasPrice: String

        /// Chain ID that this transaction is valid on.
        public var chainId: String?

        /// from address
        public var from: String?

        public var blockHash: String?

        public var blockNumber: String?

        /// Transaction hash
        public var hash: String?

        public var transactionIndex: String?

        /// Signature 'v' component
        public var v: String?

        /// Signature 'r' component
        public var r: String?

        /// Signature 's' component
        public var s: String?
        public init(type: String, nonce: String, to: String?, gas: String, value: String, input: String, gasPrice: String, chainId: String?, from: String?, blockHash: String?, blockNumber: String?, hash: String?, transactionIndex: String?, v: String?, r: String?, s: String?) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.input = input
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
        public var type: String

        public var nonce: String

        /// to address
        public var to: String?

        /// gas limit
        public var gas: String

        public var value: String

        /// input data
        public var input: String

        /// The gas price willing to be paid by the sender in wei
        public var gasPrice: String

        /// EIP-2930 access list
        public var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        public var chainId: String

        /// from address
        public var from: String?

        public var blockHash: String?

        public var blockNumber: String?

        /// Transaction hash
        public var hash: String?

        public var transactionIndex: String?

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        public var yParity: String?

        /// Signature 'r' component
        public var r: String?

        /// Signature 's' component
        public var s: String?

        public init(type: String, nonce: String, to: String?, gas: String, value: String, input: String, gasPrice: String, accessList: [EthRpc1.AccessListEntry], chainId: String, from: String?, blockHash: String?, blockNumber: String?, hash: String?, transactionIndex: String?, yParity: String?, r: String?, s: String?) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.input = input
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
        public var type: String

        public var nonce: String

        /// to address
        public var to: String?

        /// gas limit
        public var gas: String

        public var value: String

        /// input data
        public var input: String

        /// Maximum fee per gas the sender is willing to pay to miners in wei
        public var maxPriorityFeePerGas: String

        /// The maximum total fee per gas the sender is willing to pay (includes the network / base fee and miner / priority fee) in wei
        public var maxFeePerGas: String

        /// EIP-2930 access list
        public var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        public var chainId: String

        /// from address
        public var from: String?

        public var blockHash: String?

        public var blockNumber: String?

        /// Transaction hash
        public var hash: String?

        public var transactionIndex: String?

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        public var yParity: String?

        /// Signature 'r' component
        public var r: String?

        /// Signature 's' component
        public var s: String?

        public init(type: String, nonce: String, to: String?, gas: String, value: String, input: String, maxPriorityFeePerGas: String, maxFeePerGas: String, accessList: [EthRpc1.AccessListEntry], chainId: String, from: String?, blockHash: String?, blockNumber: String?, hash: String?, transactionIndex: String?, yParity: String?, r: String?, s: String?) {
            self.type = type
            self.nonce = nonce
            self.to = to
            self.gas = gas
            self.value = value
            self.input = input
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
        public var effectiveGasPrice: String

        public init(transactionHash: String, transactionIndex: String, blockHash: String, blockNumber: String, from: String, to: String?, cumulativeGasUsed: String, gasUsed: String, contractAddress: String?, logs: [EthRpc1.Log], logsBloom: String, root: String?, status: String?, effectiveGasPrice: String) {
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
        public var address: String?
        public var storageKeys: [String]?

        public init(address: String?, storageKeys: [String]?) {
            self.address = address
            self.storageKeys = storageKeys
        }
    }
}

extension EthRpc1 {
    /// Returns the balance of the account of given address.
    public struct eth_getBalance: JsonRpc2Method, EhtRpc1AccountParams {
        /// Account to get balance of
        public var address: String

        /// Block number or tag
        public var block: String

        /// Balance
        public typealias Return = String
        
        public init(address: String, block: String) {
            self.address = address
            self.block = block
        }
    }

    /// Returns the number of the most recent block seen by this client
    public struct eth_blockNumber: JsonRpc2Method, EthRpc1EmptyParams {
        /// number of the latest block
        public typealias Return = String

        public init() {}
    }


    /// Returns the current price per gas in wei.
    public struct eth_gasPrice: JsonRpc2Method, EthRpc1EmptyParams {
        /// Gas price
        public typealias Return = String

        public init() {}
    }

    /// Executes a new message call immediately without creating a transaction on the block chain.
    public struct eth_call: JsonRpc2Method, EthRpc1TransactionParams {
        /// Transaction. NOTE: `from` field MUST be present.
        public var transaction: Transaction

        /// Return data
        public typealias Return = String

        public init(transaction: EthRpc1.Transaction) {
            self.transaction = transaction
        }
    }

    /// Generates and returns an estimate of how much gas is necessary to allow the transaction to complete.
    public struct eth_estimateGas: JsonRpc2Method, EthRpc1TransactionParams {
        /// Transaction. NOTE: `from` field MUST be present.
        public var transaction: Transaction

        /// Gas used
        public typealias Return = String

        public init(transaction: EthRpc1.Transaction) {
            self.transaction = transaction
        }
    }

    /// Submits a raw transaction.
    public struct eth_sendRawTransaction: JsonRpc2Method, EthRpc1TransactionParams {
        /// Transaction as bytes
        public var transaction: String

        /// Transaction hash, or the zero hash if the transaction is not yet available
        public typealias Return = String

        public init(transaction: String) {
            self.transaction = transaction
        }
    }

    /// Returns the receipt of a transaction by transaction hash.
    public struct eth_getTransactionReceipt: JsonRpc2Method {
        public var transactionHash: String

        /// Receipt Information or null if transaction not found
        public typealias Return = ReceiptInfo?

        public init(transactionHash: String) {
            self.transactionHash = transactionHash
        }
    }

    /// Returns the number of transactions sent from an address.
    public struct eth_getTransactionCount: JsonRpc2Method, EhtRpc1AccountParams {
        /// Account to get balance of
        public var address: String

        /// Block number or tag
        public var block: String

        /// Transaction count
        public typealias Return = String

        public init(address: String, block: String) {
            self.address = address
            self.block = block
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
public protocol EhtRpc1AccountParams: Codable {
    var address: String { get set }
    var block: String { get set }
    init(address: String, block: String)
}

extension EhtRpc1AccountParams {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let address = try container.decode(String.self)
        let block = try container.decode(String.self)
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

extension EthRpc1.eth_getTransactionReceipt: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let transaction = try container.decode(String.self)
        self.init(transactionHash: transaction)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transactionHash)
    }
}
