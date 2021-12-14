//
//  EthRpc1Requests.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

extension EthRpc1 {
    /// Returns the current price per gas in wei.
    enum eth_gasPrice {
        static func request() -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_gasPrice", params: nil)
        }
        /// No parameters
        typealias Params = JsonRpc2.EmptyParams

        /// Gas price
        typealias Result = String
    }

    /// Executes a new message call immediately without creating a transaction on the block chain.
    enum eth_call {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_call", params: params)
        }

        /// Transaction. NOTE: `from` field MUST be present.
        typealias Params = TransactionParams

        /// Return data
        typealias Result = String
    }

    /// Generates and returns an estimate of how much gas is necessary to allow the transaction to complete.
    enum eth_estimateGas {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_estimateGas", params: params)
        }

        /// Transaction. NOTE: `from` field MUST be present.
        typealias Params = TransactionParams
        /// Gas used
        typealias Result = String
    }

    /// Submits a raw transaction.
    enum eth_sendRawTransaction {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_sendRawTransaction", params: params)
        }

        /// Transaction as bytes
        struct Params {
            var transaction: String
        }

        /// Transaction hash, or the zero hash if the transaction is not yet available
        typealias Result = String
    }

    /// Returns the receipt of a transaction by transaction hash.
    enum eth_getTransactionReceipt {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_getTransactionReceipt", params: params)
        }

        /// Transaction hash bytes
        struct Params {
            var transactionHash: String
        }

        /// Receipt Information or null if transaction not found
        typealias Result = ReceiptInfo?
    }

    /// Returns the balance of the account of given address.
    enum eth_getBalance {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_getBalance", params: params)
        }

        typealias Params = AccountParams
        /// Balance
        typealias Result = String
    }

    /// Returns the number of transactions sent from an address.
    enum eth_getTransactionCount {
        static func request(_ params: Params) -> JsonRpc2.Request<Params> {
            .init(jsonrpc: "2.0", method: "eth_getTransactionCount", params: params)
        }

        typealias Params = AccountParams
        /// Transaction count
        #warning("TODO: double-check because EIP-1474 and the OpenRPC spec differ types: String vs [String]")
        typealias Result = String
    }

    /// Parameters for the requests for state of an account
    struct AccountParams {
        /// account address
        var address: String
        /// block number or tag ("earliest", "latest", "pending")
        var block: String
    }

    /// Parameters for the requests related to transactions
    struct TransactionParams {
        var transaction: Transaction
    }
}

extension EthRpc1.eth_sendRawTransaction.Params: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        transaction = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transaction)
    }
}

extension EthRpc1.eth_getTransactionReceipt.Params: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        transactionHash = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transactionHash)
    }
}

extension EthRpc1.AccountParams: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        address = try container.decode(String.self)
        block = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(block)
    }
}

extension EthRpc1.TransactionParams: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        transaction = try container.decode(EthRpc1.Transaction.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transaction)
    }
}
