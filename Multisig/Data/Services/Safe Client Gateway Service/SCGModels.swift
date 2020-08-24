//
//  SCGModels.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Page<T: Decodable>: Decodable {
    let next: String?
    let previous: String?
    let results: [T]
}

struct TransactionSummary: Decodable {
    let id: TransactionID
    let timestamp: Date
    let txStatus: SCGTransactionStatus
    let txInfo: TransactionInfo
    let executionInfo: ExecutionInfo?
}

extension TransactionSummary {

    enum Key: String, CodingKey {
        case id, timestamp, txStatus, txInfo, executionInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        id = try container.decode(TransactionID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        txStatus = try container.decode(SCGTransactionStatus.self, forKey: .txStatus)
        txInfo = try container.decode(TransactionInfoWrapper.self, forKey: .txInfo).value
        executionInfo = try container.decodeIfPresent(ExecutionInfo.self, forKey: .executionInfo)
    }
}

struct TransactionID: Decodable, CustomStringConvertible {
    let value: String
}

extension TransactionID {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    var description: String {
        value
    }
}

enum SCGTransactionStatus: String, Decodable {
    case awaitingConfirmations = "AWAITING_CONFIRMATIONS"
    case awaitingExecution = "AWAITING_EXECUTION"
    case cancelled = "CANCELLED"
    case failed = "FAILED"
    case success = "SUCCESS"
}

struct ExecutionInfo: Decodable {
    let nonce: UInt64
    let confirmationsRequired: UInt64
    let confirmationsSubmitted: UInt64
}

protocol TransactionInfo: Decodable {}

enum TransactionInfoType: String, Decodable {
    case transfer
    case settingsChange
    case custom
    case creation
    case unknown
}

enum TransactionInfoWrapper: Decodable {
    case transfer(TransferTransactionInfo)
    case settingsChange(SettingsChangeTransactionInfo)
    case custom(CustomTransactionInfo)
    case creation(CreationTransactionInfo)
    case unknown(UnknownTransactionInfo)

    var value: TransactionInfo {
        switch self {
        case .transfer(let value):
            return value
        case .settingsChange(let value):
            return value
        case .custom(let value):
            return value
        case .creation(let value):
            return value
        case .unknown(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(TransactionInfoType.self, forKey: .type)
        switch type {
        case .transfer:
            self = try .transfer(TransferTransactionInfo(from: decoder))
        case .settingsChange:
            self = try .settingsChange(SettingsChangeTransactionInfo(from: decoder))
        case .custom:
            self = try .custom(CustomTransactionInfo(from: decoder))
        case .creation:
            self = try .creation(CreationTransactionInfo(from: decoder))
        case .unknown:
            self = try .unknown(UnknownTransactionInfo(from: decoder))
        }
    }
}

struct SettingsChangeTransactionInfo: TransactionInfo {
    let dataDecoded: DataDecoded
}

struct CustomTransactionInfo: TransactionInfo {
    let to: AddressString
    let dataSize: UInt256String
    let value: UInt256String
}

struct  UnknownTransactionInfo: TransactionInfo {
}

struct CreationTransactionInfo: TransactionInfo {
    let creator: AddressString
    let transactionHash: DataString
    let masterCopy: AddressString?
    let factory: AddressString?
}

struct TransferTransactionInfo: TransactionInfo {
    let sender: AddressString
    let recipient: AddressString
    let direction: TransferDirection
    let transferInfo: SCGTransferInfo
}

extension TransferTransactionInfo {
    enum Key: String, CodingKey {
        case sender, recipient, direction, transferInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        sender = try container.decode(AddressString.self, forKey: .sender)
        recipient = try container.decode(AddressString.self, forKey: .recipient)
        direction = try container.decode(TransferDirection.self, forKey: .direction)
        transferInfo = try container.decode(TransferInfoWrapper.self, forKey: .transferInfo).value
    }
}

enum TransferDirection: String, Decodable {
    case incoming = "INCOMING"
    case outgoing = "OUTGOING"
    case unknown = "UNKNOWN"
}

protocol SCGTransferInfo: Decodable {}

enum TransferInfoType: String, Decodable {
    case erc20 = "ERC20"
    case erc721 = "ERC721"
    case ether = "ETHER"
}

enum TransferInfoWrapper: Decodable {
    case erc20(Erc20TransferInfo)
    case erc721(Erc721TransferInfo)
    case ether(EtherTransferInfo)

    var value: SCGTransferInfo {
        switch self {
        case .erc20(let value):
            return value
        case .erc721(let value):
            return value
        case .ether(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(TransferInfoType.self, forKey: .type)
        switch type {
        case .erc20:
            self = try .erc20(Erc20TransferInfo(from: decoder))
        case .erc721:
            self = try .erc721(Erc721TransferInfo(from: decoder))
        case .ether:
            self = try .ether(EtherTransferInfo(from: decoder))
        }
    }
}

struct Erc20TransferInfo: SCGTransferInfo {
    let tokenAddress: AddressString
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
    let decimals: UInt64?
    let value: UInt256String
}

struct Erc721TransferInfo: SCGTransferInfo {
    let tokenAddress: AddressString
    let tokenId: UInt256String
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
}

struct EtherTransferInfo: SCGTransferInfo {
    let value: UInt256String
}

enum Operation: Int, Decodable {
    case call = 0
    case delegate = 1
}

struct DataDecoded: Decodable {
    let method: String
    let parameters: [DataDecodedParameter]?
}

struct DataDecodedParameter: Decodable {
    let name: String
    let type: String
    let value: DataDecodedParameterValue
}

extension DataDecodedParameter {
    enum Key: String, CodingKey {
        case name, type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        value = try container.decode(DataDecodedParameterValueWrapper.self, forKey: .value).value
    }
}

protocol DataDecodedParameterValue {}

extension DataDecodedParameterValue {
    var stringValue: String? {
        self as? String
    }

    var addressValue: Address? {
        guard let stringValue = stringValue else { return nil }
        return Address(stringValue)
    }

    var arrayValue: [DataDecodedParameterValue]? {
        self as? [DataDecodedParameterValue]
    }
}

extension String: DataDecodedParameterValue {}

extension Array: DataDecodedParameterValue where Element == DataDecodedParameterValue {}

enum DataDecodedParameterValueWrapper: Decodable {
    case stringValue(String)
    case arrayValue([DataDecodedParameterValueWrapper])

    var value: DataDecodedParameterValue {
        switch self {
        case .stringValue(let value):
            return value
        case .arrayValue(let array):
            return array.map { $0.value }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = (try? container.decode(String.self)) {
            self = .stringValue(string)
        } else {
            self = try .arrayValue(container.decode([DataDecodedParameterValueWrapper].self))
        }
    }
}

// MARK: - Details

struct TransactionDetails: Decodable {
    let executedAt: Date
    let txStatus: SCGTransactionStatus
    let txInfo: TransactionInfo
    let txData: TransactionDetailsData
    let detailedExecutionInfo: DetailedExecutionInfo?
    let txHash: DataString?
}

extension TransactionDetails {
    enum Key: String, CodingKey {
        case executedAt, txStatus, txInfo, txData, detailedExecutionInfo, txHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        executedAt = try container.decode(Date.self, forKey: .executedAt)
        txStatus = try container.decode(SCGTransactionStatus.self, forKey: .txStatus)
        txInfo = try container.decode(TransactionInfoWrapper.self, forKey: .txInfo).value
        txData = try container.decode(TransactionDetailsData.self, forKey: .txData)
        detailedExecutionInfo = try container.decodeIfPresent(DetailedExecutionInfoWrapper.self, forKey: .detailedExecutionInfo)?.value
        txHash = try container.decodeIfPresent(DataString.self, forKey: .txHash)
    }
}

struct TransactionDetailsData: Decodable {
    let hexData: DataString?
    let dataDecoded: DataDecoded?
    let to: AddressString
    let value: UInt256String
    let operation: Operation
}

protocol DetailedExecutionInfo: Decodable {}

enum DetailedExecutionInfoType: String, Decodable {
    case module = "MODULE"
    case multisig = "MULTISIG"
}

enum DetailedExecutionInfoWrapper: Decodable {
    case module(ModuleExecutionDetails)
    case multisig(MultisigExecutionDetails)

    var value: DetailedExecutionInfo {
        switch self {
        case .module(let value):
            return value
        case .multisig(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(DetailedExecutionInfoType.self, forKey: .type)
        switch type {
        case .module:
            self = try .module(ModuleExecutionDetails(from: decoder))
        case .multisig:
            self = try .multisig(MultisigExecutionDetails(from: decoder))
        }
    }
}

struct ModuleExecutionDetails: DetailedExecutionInfo {
    let address: AddressString
}

struct MultisigExecutionDetails: DetailedExecutionInfo {
    let submittedAt: Date
    let nonce: UInt64
    let safeTxHash: DataString
    let signers: [AddressString]
    let confirmationsRequired: UInt64
    let confirmations: [MultisigConfirmation]
}

struct MultisigConfirmation: Decodable {
    let signer: AddressString
    let signature: DataString
}
