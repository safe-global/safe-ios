//
//  SCGModels.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SCGPage<T: Decodable>: Decodable {
    let next: String?
    let previous: String?
    let results: [T]
}

struct SCGTransactionSummary: Decodable {
    let id: SCGTransactionID
    let timestamp: Date
    let txStatus: SCGTransactionStatus
    let txInfo: SCGTransactionInfo
    let executionInfo: SCGExecutionInfo?
}

extension SCGTransactionSummary {

    enum Key: String, CodingKey {
        case id, timestamp, txStatus, txInfo, executionInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        id = try container.decode(SCGTransactionID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        txStatus = try container.decode(SCGTransactionStatus.self, forKey: .txStatus)
        txInfo = try container.decode(SCGTransactionInfoWrapper.self, forKey: .txInfo).value
        executionInfo = try container.decodeIfPresent(SCGExecutionInfo.self, forKey: .executionInfo)
    }
}

struct SCGTransactionID: Decodable, CustomStringConvertible {
    let value: String
}

extension SCGTransactionID {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    var description: String {
        value
    }
}

enum SCGTransactionStatus: String, Decodable {
    case AWAITING_CONFIRMATIONS
    case AWAITING_EXECUTION
    case CANCELLED
    case FAILED
    case SUCCESS
}

struct SCGExecutionInfo: Decodable {
    let nonce: UInt64
    let confirmationsRequired: UInt64
    let confirmationsSubmitted: UInt64
}

protocol SCGTransactionInfo: Decodable {}

enum SCGTransactionInfoType: String, Decodable {
    case Transfer
    case SettingsChange
    case Custom
    case Creation
    case Unknown
}

enum SCGTransactionInfoWrapper: Decodable {
    case Transfer(SCGTransfer)
    case SettingsChange(SCGSettingsChange)
    case Custom(SCGCustom)
    case Creation(SCGCreation)
    case Unknown(SCGUnknown)

    var value: SCGTransactionInfo {
        switch self {
        case .Transfer(let value):
            return value
        case .SettingsChange(let value):
            return value
        case .Custom(let value):
            return value
        case .Creation(let value):
            return value
        case .Unknown(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(SCGTransactionInfoType.self, forKey: .type)
        switch type {
        case .Transfer:
            self = try .Transfer(SCGTransfer(from: decoder))
        case .SettingsChange:
            self = try .SettingsChange(SCGSettingsChange(from: decoder))
        case .Custom:
            self = try .Custom(SCGCustom(from: decoder))
        case .Creation:
            self = try .Creation(SCGCreation(from: decoder))
        case .Unknown:
            self = try .Unknown(SCGUnknown(from: decoder))
        }
    }
}

struct SCGSettingsChange: SCGTransactionInfo {
    let dataDecoded: SCGDataDecoded
}

struct SCGCustom: SCGTransactionInfo {
    let to: AddressString
    let dataSize: UInt256String
    let value: UInt256String
}

struct  SCGUnknown: SCGTransactionInfo {
}

struct SCGCreation: SCGTransactionInfo {
    let creator: AddressString
    let transactionHash: DataString
    let masterCopy: AddressString?
    let factory: AddressString?
}

struct SCGTransfer: SCGTransactionInfo {
    let sender: AddressString
    let recipient: AddressString
    let direction: SCGTransferDirection
    let transferInfo: SCGTransferInfo
}

extension SCGTransfer {
    enum Key: String, CodingKey {
        case sender, recipient, direction, transferInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        sender = try container.decode(AddressString.self, forKey: .sender)
        recipient = try container.decode(AddressString.self, forKey: .recipient)
        direction = try container.decode(SCGTransferDirection.self, forKey: .direction)
        transferInfo = try container.decode(SCGTransferInfoWrapper.self, forKey: .transferInfo).value
    }
}

enum SCGTransferDirection: String, Decodable {
    case INCOMING
    case OUTGOING
    case UNKNOWN
}

protocol SCGTransferInfo: Decodable {}

enum SCGTransferInfoType: String, Decodable {
    case ERC20
    case ERC721
    case ETHER
}

enum SCGTransferInfoWrapper: Decodable {
    case erc20(SCGErc20Transfer)
    case erc721(SCGErc721Transfer)
    case ether(SCGEtherTransfer)

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
        let type = try container.decode(SCGTransferInfoType.self, forKey: .type)
        switch type {
        case .ERC20:
            self = try .erc20(SCGErc20Transfer(from: decoder))
        case .ERC721:
            self = try .erc721(SCGErc721Transfer(from: decoder))
        case .ETHER:
            self = try .ether(SCGEtherTransfer(from: decoder))
        }
    }
}

struct SCGErc20Transfer: SCGTransferInfo {
    let tokenAddress: AddressString
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
    let decimals: UInt64?
    let value: UInt256String
}

struct SCGErc721Transfer: SCGTransferInfo {
    let tokenAddress: AddressString
    let tokenId: UInt256String
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
}

struct SCGEtherTransfer: SCGTransferInfo {
    let value: UInt256String
}

enum SCGOperation: Int, Decodable {
    case call = 0
    case delegate = 1
}

struct SCGDataDecoded: Decodable {
    let method: String
    let parameters: [SCGParameter]?
}

struct SCGParameter: Decodable {
    let name: String
    let type: String
    let value: SCGParamValue
}

extension SCGParameter {
    enum Key: String, CodingKey {
        case name, type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        value = try container.decode(SCGParamValueWrapper.self, forKey: .value).value
    }
}

protocol SCGParamValue {}

extension String: SCGParamValue {}

extension Array: SCGParamValue where Element == SCGParamValue {}

enum SCGParamValueWrapper: Decodable {
    case stringValue(String)
    case arrayValue([SCGParamValueWrapper])

    var value: SCGParamValue {
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
            self = try .arrayValue(container.decode([SCGParamValueWrapper].self))
        }
    }
}

// MARK: - Details

struct SCGTransactionDetails: Decodable {
    let executedAt: Date
    let txStatus: SCGTransactionStatus
    let txInfo: SCGTransactionInfo
    let txData: SCGTransactionData
    let detailedExecutionInfo: SCGDetailedExecutionInfo?
    let txHash: DataString?
}

extension SCGTransactionDetails {
    enum Key: String, CodingKey {
        case executedAt, txStatus, txInfo, txData, detailedExecutionInfo, txHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        executedAt = try container.decode(Date.self, forKey: .executedAt)
        txStatus = try container.decode(SCGTransactionStatus.self, forKey: .txStatus)
        txInfo = try container.decode(SCGTransactionInfoWrapper.self, forKey: .txInfo).value
        txData = try container.decode(SCGTransactionData.self, forKey: .txData)
        detailedExecutionInfo = try container.decodeIfPresent(SCGDetailedExecutionInfoWrapper.self, forKey: .detailedExecutionInfo)?.value
        txHash = try container.decodeIfPresent(DataString.self, forKey: .txHash)
    }
}

struct SCGTransactionData: Decodable {
    let hexData: DataString?
    let dataDecoded: SCGDataDecoded?
    let to: AddressString
    let value: UInt256String
    let operation: SCGOperation
}

protocol SCGDetailedExecutionInfo: Decodable {}

enum SCGDetailedExecutionInfoType: String, Decodable {
    case MODULE
    case MULTISIG
}

enum SCGDetailedExecutionInfoWrapper: Decodable {
    case Module(SCGModuleExecutionDetails)
    case Multisig(SCGMultisigExecutionDetails)

    var value: SCGDetailedExecutionInfo {
        switch self {
        case .Module(let value):
            return value
        case .Multisig(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(SCGDetailedExecutionInfoType.self, forKey: .type)
        switch type {
        case .MODULE:
            self = try .Module(SCGModuleExecutionDetails(from: decoder))
        case .MULTISIG:
            self = try .Multisig(SCGMultisigExecutionDetails(from: decoder))
        }
    }
}

struct SCGModuleExecutionDetails: SCGDetailedExecutionInfo {
    let address: AddressString
}

struct SCGMultisigExecutionDetails: SCGDetailedExecutionInfo {
    let submittedAt: Date
    let nonce: UInt64
    let safeTxHash: DataString
    let signers: [AddressString]
    let confirmationsRequired: UInt64
    let confirmations: [SCGMultisigConfirmation]
}

struct SCGMultisigConfirmation: Decodable {
    let signer: AddressString
    let signature: DataString
}
