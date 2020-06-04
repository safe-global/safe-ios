//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation


struct Transaction: Decodable, Identifiable, Hashable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return true
    }

    var id: Int {
        return safeTxHash.hashValue
    }

    func hash(into hasher: inout Hasher) {

    }

    let safe: String?
    let to: String?
    let value: String?
    let data: String?
    let operation: Int?
    let gasToken: String?
    let safeTxGas: Int?
    let baseGas: Int?
    let gasPrice: String?
    let refundReceiver: String?
    let nonce: Int?
    let executionDate: String?
    let submissionDate: String?
    let modified: String?
    let blockNumber: Int?
    let transactionHash: String?
    let safeTxHash: String?
    let executor: String?
    let isExecuted: Bool?
    let isSuccessful: Bool?
    let tokenAddress: String?
    let ethGasPrice: String?
    let gasUsed: Int?
    let fee: String?
    let origin: String?
    let dataDecoded: DecodedData?
    let confirmationsRequired: Int?
    let confirmations: [TrnasactionConfirmation]?
    let signatures: String?
    let transfers: [Transfer]?
    let txType: TransactionType?
}

struct TrnasactionConfirmation: Decodable {
    let owner: String
    let submissionDate: String
    let transactionHash: String?
    let data: String?
    let signature: String?
    let signatureType: SignatureType?
}

struct Transfer: Decodable {
    let type: TransferType
    let executionDate: String?
    let blockNumber: Int?
    let transactionHash: String?
    let to: String?
    let value: String?
    let tokenId: Int?
    let tokenAddress: String? // should be removed when tokenInfo implemented https://github.com/gnosis/safe-transaction-service/issues/96
    let tokenInfo: TokenInfo?
    let from: String?
}

struct DecodedData {
    let method: String
    let parameters: [DecodedDataParameter]

    init(from decoder: Decoder) throws {
        method = ""
        parameters = []
    }
}

struct DecodedDataParameter: Decodable {
    let name: String
    let type: String
    let value: String
}

enum TransactionType: String, Decodable {
    case multiSig = "MULTISIG_TRANSACTION"
    case ethereum = "ETHEREUM_TRANSACTION"
    case module = "MODULE_TRANSACTION"
}

enum TransferType: String, Decodable {
    case ether = "ETHER_TRANSFER"
    case erc20 = "ERC20_TRANSFER"
    case erc721 = "ERC721_TRANSFER"
    case unknown = "UNKNOWN"
}

enum SignatureType: String, Decodable {
    case contractSignature = "CONTRACT_SIGNATURE"
    case approvedHash = "APPROVED_HASH"
    case eoa = "EOA"
    case ethSignature = "ETH_SIGN"
}

struct TokenInfo: Decodable {
    let address: String
    let decimals: Int?
    let symbol: String?
    let name: String?
    let logoUri: String?
    let tokenType: TokenType?
}

enum TokenType: String, Decodable {
    case erc20 = "ERC20"
    case erc721 = "ERC721"
}

enum TransactionStatus {
    case success
    case pending
    case canceled
    case failed
    case waitingConfirmation
    case waitingExecution
}
