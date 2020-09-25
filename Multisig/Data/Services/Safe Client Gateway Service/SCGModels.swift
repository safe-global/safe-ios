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

protocol Transaction {
    var txInfo: TransactionInfo { get set }
    var txStatus: TransactionStatus { get set }
}

struct TransactionSummary: Transaction {
    let id: TransactionID
    let date: Date
    var txStatus: TransactionStatus
    var txInfo: TransactionInfo
    let executionInfo: ExecutionInfo?
}

extension TransactionSummary: Decodable {

    enum Key: String, CodingKey {
        case id, timestamp, txStatus, txInfo, executionInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        id = try container.decode(TransactionID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .timestamp)
        txStatus = try container.decode(TransactionStatus.self, forKey: .txStatus)
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

enum TransactionStatus: String, Decodable {
    case awaitingConfirmations = "AWAITING_CONFIRMATIONS"
    case awaitingExecution = "AWAITING_EXECUTION"
    case cancelled = "CANCELLED"
    case failed = "FAILED"
    case success = "SUCCESS"
    case pending = "PENDING"
}

struct ExecutionInfo: Decodable {
    let nonce: UInt256String
    let confirmationsRequired: UInt64
    let confirmationsSubmitted: UInt64
}

protocol TransactionInfo: Decodable {}

enum TransactionInfoType: String, Decodable {
    case transfer = "Transfer"
    case settingsChange = "SettingsChange"
    case custom = "Custom"
    case creation = "Creation"
    case unknown = "Unknown"
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
    let settingsInfo: SettingsChangeTransactionSummaryInfo?
}

extension SettingsChangeTransactionInfo {
    enum Key: String, CodingKey {
        case dataDecoded, settingsInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        dataDecoded = try container.decode(DataDecoded.self, forKey: .dataDecoded)
        settingsInfo = try container.decode(SettingsChangeTransactionInfoWrapper.self, forKey: .settingsInfo).value
    }
}

protocol SettingsChangeTransactionSummaryInfo: Decodable {}

enum SettingsChangeTransactionInfoType: String, Decodable {
    case setFallbackHandler = "SET_FALLBACK_HANDLER"
    case addOwner = "ADD_OWNER"
    case removeOwner = "REMOVE_OWNER"
    case swapOwner = "SWAP_OWNER"
    case changeThreshold = "CHANGE_THRESHOLD"
    case changeImplementation = "CHANGE_IMPLEMENTATION"
    case enableModule = "ENABLE_MODULE"
    case disableModule = "DISABLE_MODULE"
}

enum SettingsChangeTransactionInfoWrapper: Decodable {
    case setFallbackHandler(SetFallbackHandlerSettingsChangeTransactionSummaryInfo)
    case addOwner(AddOwnerSettingsChangeTransactionSummaryInfo)
    case removeOwner(RemoveOwnerSettingsChangeTransactionSummaryInfo)
    case swapOwner(SwapOwnerSettingsChangeTransactionSummaryInfo)
    case changeThreshold(ChangeThresholdSettingsChangeTransactionSummaryInfo)
    case changeImplementation(ChangeImplementationSettingsChangeTransactionSummaryInfo)
    case enableModule(EnableModuleSettingsChangeTransactionSummaryInfo)
    case disableModule(DisableModuleSettingsChangeTransactionSummaryInfo)

    var value: SettingsChangeTransactionSummaryInfo {
        switch self {
        case .setFallbackHandler(let value):
            return value
        case .addOwner(let value):
            return value
        case .removeOwner(let value):
            return value
        case .swapOwner(let value):
            return value
        case .changeThreshold(let value):
            return value
        case .changeImplementation(let value):
            return value
        case .enableModule(let value):
            return value
        case .disableModule(let value):
            return value
        }
    }

    enum Key: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(SettingsChangeTransactionInfoType.self, forKey: .type)
        switch type {
        case .setFallbackHandler:
            self = try .setFallbackHandler(SetFallbackHandlerSettingsChangeTransactionSummaryInfo(from: decoder))
        case .addOwner:
            self = try .addOwner(AddOwnerSettingsChangeTransactionSummaryInfo(from: decoder))
        case .removeOwner:
            self = try .removeOwner(RemoveOwnerSettingsChangeTransactionSummaryInfo(from: decoder))
        case .swapOwner:
            self = try .swapOwner(SwapOwnerSettingsChangeTransactionSummaryInfo(from: decoder))
        case .changeThreshold:
            self = try .changeThreshold(ChangeThresholdSettingsChangeTransactionSummaryInfo(from: decoder))
        case .changeImplementation:
            self = try .changeImplementation(ChangeImplementationSettingsChangeTransactionSummaryInfo(from: decoder))
        case .enableModule:
            self = try .enableModule(EnableModuleSettingsChangeTransactionSummaryInfo(from: decoder))
        case .disableModule:
            self = try .disableModule(DisableModuleSettingsChangeTransactionSummaryInfo(from: decoder))
        }
    }
}

struct SetFallbackHandlerSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let handler: AddressString
}

struct AddOwnerSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let owner: AddressString
    let threshold: UInt64
}

struct RemoveOwnerSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let owner: AddressString
    let threshold: UInt64
}

struct SwapOwnerSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let newOwner: AddressString
    let oldOwner: AddressString
}

struct ChangeThresholdSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let threshold: UInt64
}

struct ChangeImplementationSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let implementation: AddressString
}

struct EnableModuleSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let module: AddressString
}

struct DisableModuleSettingsChangeTransactionSummaryInfo: SettingsChangeTransactionSummaryInfo {
    let module: AddressString
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
    let transferInfo: TransferInfo
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

protocol TransferInfo: Decodable {}

enum TransferInfoType: String, Decodable {
    case erc20 = "ERC20"
    case erc721 = "ERC721"
    case ether = "ETHER"
}

enum TransferInfoWrapper: Decodable {
    case erc20(Erc20TransferInfo)
    case erc721(Erc721TransferInfo)
    case ether(EtherTransferInfo)

    var value: TransferInfo {
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

struct Erc20TransferInfo: TransferInfo {
    let tokenAddress: AddressString
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
    let decimals: UInt64?
    let value: UInt256String
}

struct Erc721TransferInfo: TransferInfo {
    let tokenAddress: AddressString
    let tokenId: UInt256String
    let tokenName: String?
    let tokenSymbol: String?
    let logoUri: String?
}

struct EtherTransferInfo: TransferInfo {
    let value: UInt256String
}

enum Operation: Int, Decodable {
    case call = 0
    case delegate = 1

    var name: String {
        switch self {
        case .call:
            return "call"
        case .delegate:
            return "delegateCall"
        }
    }
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

    var uint256Value: UInt256? {
        guard let stringValue = stringValue else { return nil }
        return UInt256(stringValue)
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

struct TransactionDetails: Decodable, Transaction {
    let executedAt: Date?
    var txStatus: TransactionStatus
    var txInfo: TransactionInfo
    let txData: TransactionDetailsData?
    let detailedExecutionInfo: DetailedExecutionInfo?
    let txHash: DataString?
}

extension TransactionDetails {
    enum Key: String, CodingKey {
        case executedAt, txStatus, txInfo, txData, detailedExecutionInfo, txHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        executedAt = try container.decodeIfPresent(Date.self, forKey: .executedAt)
        txStatus = try container.decode(TransactionStatus.self, forKey: .txStatus)
        txInfo = try container.decode(TransactionInfoWrapper.self, forKey: .txInfo).value
        txData = try container.decodeIfPresent(TransactionDetailsData.self, forKey: .txData)
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
    let nonce: UInt256String
    let safeTxGas: UInt256String
    let baseGas: UInt256String
    let gasPrice: UInt256String
    let gasToken: AddressString
    let refundReceiver: AddressString
    let safeTxHash: DataString
    let signers: [AddressString]
    let confirmationsRequired: UInt64
    let confirmations: [MultisigConfirmation]
}

struct MultisigConfirmation: Decodable {
    let signer: AddressString
    let signature: DataString
}
