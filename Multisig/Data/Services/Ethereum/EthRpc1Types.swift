//
//  EthRpc1Types.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Namespace for the types defined in the Ethereum JSON-RPC 1.0 specification
///
/// See more:
///   - https://raw.githubusercontent.com/ethereum/eth1.0-apis/assembled-spec/openrpc.json
///   - https://eips.ethereum.org/EIPS/eip-1474
enum EthRpc1 { 
    enum Transaction: Codable {
        case legacy(TransactionLegacy)
        case eip2930(Transaction2930)
        case eip1559(Transaction1559)
        /// not known type
        case unknown

        init(from decoder: Decoder) throws {
            enum Key: String, CodingKey { case type }
            let container = try decoder.container(keyedBy: Key.self)
            let type = try container.decode(String.self, forKey: .type)
            guard let byte = Data(ethHex: type).bytes.first else {
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

    struct TransactionLegacy: Codable {
        /// type according to EIP-2718
        ///
        /// Must be in range [0xc0, 0xfe]
        var type: String

        var nonce: String

        /// to address
        var to: String?

        /// gas limit
        var gas: String

        var value: String

        /// input data
        var input: String

        /// The gas price willing to be paid by the sender in wei
        var gasPrice: String

        /// Chain ID that this transaction is valid on.
        var chainId: String?

        /// from address
        var from: String?

        var blockHash: String?

        var blockNumber: String?

        /// Transaction hash
        var hash: String?

        var transactionIndex: String?

        /// Signature 'v' component
        var v: String?

        /// Signature 'r' component
        var r: String?

        /// Signature 's' component
        var s: String?
    }

    /// EIP-2930 transaction.
    struct Transaction2930: Codable {
        /// type according to EIP-2718
        ///
        /// Must be 0x01 per specification
        var type: String

        var nonce: String

        /// to address
        var to: String?

        /// gas limit
        var gas: String

        var value: String

        /// input data
        var input: String

        /// The gas price willing to be paid by the sender in wei
        var gasPrice: String

        /// EIP-2930 access list
        var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        var chainId: String

        /// from address
        var from: String?

        var blockHash: String?

        var blockNumber: String?

        /// Transaction hash
        var hash: String?

        var transactionIndex: String?

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        var yParity: String?

        /// Signature 'r' component
        var r: String?

        /// Signature 's' component
        var s: String?
    }

    /// EIP-1559 transaction.
    struct Transaction1559: Codable {
        /// type according to EIP-2718
        ///
        /// Must be 0x02 per specification
        var type: String

        var nonce: String

        /// to address
        var to: String?

        /// gas limit
        var gas: String

        var value: String

        /// input data
        var input: String

        /// Maximum fee per gas the sender is willing to pay to miners in wei
        var maxPriorityFeePerGas: String

        /// The maximum total fee per gas the sender is willing to pay (includes the network / base fee and miner / priority fee) in wei
        var maxFeePerGas: String

        /// EIP-2930 access list
        var accessList: [AccessListEntry]

        /// Chain ID that this transaction is valid on.
        var chainId: String

        /// from address
        var from: String?

        var blockHash: String?

        var blockNumber: String?

        /// Transaction hash
        var hash: String?

        var transactionIndex: String?

        /// The parity (0 for even, 1 for odd) of the y-value of the secp256k1 signature.
        var yParity: String?

        /// Signature 'r' component
        var r: String?

        /// Signature 's' component
        var s: String?
    }

    struct Log: Codable {
        var removed: Bool?
        var logIndex: String?
        var transactionIndex: String?
        var transactionHash: String?
        var blockHash: String?
        var blockNumber: String?
        var address: String?
        var data: String?
        var topics: [String]?
    }

    struct ReceiptInfo: Codable {
        var transactionHash: String

        var transactionIndex: String

        var blockHash: String

        var blockNumber: String

        var from: String

        /// Address of the receiver or null in a contract creation transaction.
        var to: String?

        /// The sum of gas used by this transaction and all preceding transactions in the same block.
        var cumulativeGasUsed: String

        /// The amount of gas used for this specific transaction alone.
        var gasUsed: String

        /// The contract address created, if the transaction was a contract creation, otherwise null.
        var contractAddress: String?

        var logs: [Log]

        var logsBloom: String

        /// The post-transaction state root. Only specified for transactions included before the Byzantium upgrade.
        var root: String?

        /// Either 1 (success) or 0 (failure). Only specified for transactions included after the Byzantium upgrade.
        var status: String?

        /// The actual value per gas deducted from the senders account. Before EIP-1559, this is equal to the transaction's gas price. After, it is equal to baseFeePerGas + min(maxFeePerGas - baseFeePerGas, maxPriorityFeePerGas).
        var effectiveGasPrice: String
    }

    /// Access list entry
    struct AccessListEntry: Codable {
        var address: String?
        var storageKeys: [String]?
    }
}

