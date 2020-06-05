//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt



struct Transaction: Decodable, Identifiable, Hashable {

    var id: Int {
        return hashValue
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
    let executionDate: Date?
    let submissionDate: Date?
    let modified: Date?
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

extension Transaction {

    func status(safeNonce: Int, safeThreshold: Int) -> TransactionStatus {
        // tx-es without nonce are external transactions that are
        // already executed successfully.
        guard let nonce = nonce else { return .success }
        let confirmationCount = confirmations?.count ?? 0
        let threshold = confirmationsRequired ?? safeThreshold

        if isExecuted == true && isSuccessful == true {
            return .success
        } else if isExecuted == true && isSuccessful != true {
            return .failed
        } else if isExecuted != true && nonce < safeNonce {
            return .canceled
        } else if isExecuted != true && nonce >= safeNonce && confirmationCount < threshold {
            return .waitingConfirmation
        } else if isExecuted != true && nonce >= safeNonce && confirmationCount >= threshold {
            return .waitingExecution
        } else {
            return .pending
        }
    }
}

struct TrnasactionConfirmation: Decodable, Hashable {
    let owner: String
    let submissionDate: Date
    let transactionHash: String?
    let data: String?
    let signature: String?
    let signatureType: SignatureType?
}

struct Transfer: Decodable, Hashable {
    let type: TransferType
    let executionDate: Date?
    let blockNumber: Int?
    let transactionHash: String?
    let to: String?
    let value: String?
    let tokenId: String?
    let tokenAddress: String? // should be removed when tokenInfo implemented https://github.com/gnosis/safe-transaction-service/issues/96
    let tokenInfo: TokenInfo?
    let from: String?
}

struct DecodedData: Decodable, Hashable {
    let method: String
    let parameters: [DecodedDataParameter]

    struct Method: CodingKey {

        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Method.self)
        guard let methodKey = container.allKeys.first else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Method not found in the decoded data")
            throw DecodingError.valueNotFound(Method.self, context)
        }
        method = methodKey.stringValue
        parameters = try container.decode([DecodedDataParameter].self, forKey: methodKey)
    }
}

struct DecodedDataParameter: Decodable, Hashable {
    let name: String
    let type: String
    let value: String

    enum CodingKeys: CodingKey {
        case name, value, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = String(intValue)
        } else {
            value = try container.decode(String.self, forKey: .value)
        }
    }

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

struct TokenInfo: Decodable, Hashable {
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

    var title: String {
        switch self {
        case .waitingExecution:
            return "Awaiting execution"
        case .waitingConfirmation:
            return "Awaiting confirmations"
        case .pending:
             return "Pending"
        case .failed:
            return "Failed"
        case .canceled:
            return "Canceled"
        case .success:
            return "Success"
        }
    }
}
