//
//  SCG.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Page<T: Decodable>: Decodable {
    let next: String?
    let previous: String?
    let results: [T]
}

// SCG for Safe Client Gateway
enum SCGModels {}

extension SCGModels {
    struct TransactionSummaryItemDateLabel: Decodable {
        let timestamp: Date
    }

    struct TransactionSummaryItemLabel: Decodable {
        let label: String
    }

    struct TransactionSummaryItemTransaction: Decodable {
        let transaction: TxSummary
        let conflictType: ConflictType
    }

    struct TransactionSummaryItemConflictHeader: Decodable {
        let nonce: UInt256String
    }

    enum TransactionSummaryItem: Decodable {
        case dateLabel(TransactionSummaryItemDateLabel)
        case label(TransactionSummaryItemLabel)
        case transaction(TransactionSummaryItemTransaction)
        case conflictHeader(TransactionSummaryItemConflictHeader)
        case unknown

        init(from decoder: Decoder) throws {
            enum Keys: String, CodingKey { case type }
            let container = try decoder.container(keyedBy: Keys.self)
            let type = try? container.decode(String.self, forKey: .type)

            switch type {
            case "LABEL":
                self = try .label(TransactionSummaryItemLabel(from: decoder))
            case "DATE_LABEL":
                self = try .dateLabel(TransactionSummaryItemDateLabel(from: decoder))
            case "TRANSACTION":
                self = try .transaction(TransactionSummaryItemTransaction(from: decoder))
            case "CONFLICT_HEADER":
                self = try .conflictHeader(TransactionSummaryItemConflictHeader(from: decoder))
            default:
                self = .unknown
            }
        }
    }

    struct AddressInfo: Decodable {
        var name: String
        var logoUri: URL?
    }

    struct AddressInfoExtended: Decodable {
        var value: AddressString
        var name: String?
        var logoUrl: URL?
    }

    struct TxSummary: Decodable {
        var id: String
        var timestamp: Date
        var txStatus: TxStatus
        var txInfo: TxInfo
        var executionInfo: ExecutionInfo?
        var safeAppInfo: SafeAppInfo?
    }

    enum TxStatus: String, Decodable {
        case awaitingConfirmations = "AWAITING_CONFIRMATIONS"
        case awaitingYourConfirmation = "AWAITING_YOUR_CONFIRMATION"
        case awaitingExecution = "AWAITING_EXECUTION"
        case cancelled = "CANCELLED"
        case failed = "FAILED"
        case success = "SUCCESS"
        case pending = "PENDING"
    }

    struct ExecutionInfo: Decodable {
        var nonce: UInt256String
        var confirmationsRequired: UInt64
        var confirmationsSubmitted: UInt64
        var signers: [AddressString]?
        var confirmations: [Confirmation]?
        var missingSigners: [AddressString]?
    }

    struct Confirmation: Decodable {
        var signer: AddressString
        var signature: DataString
    }

    enum TxInfo: Decodable {
        case transfer(Transfer)
        case settingsChange(SettingsChange)
        case custom(Custom)
        case rejection(Rejection)
        case creation(Creation)
        case unknown

        init(from decoder: Decoder) throws {
            enum Keys: String, CodingKey {
                case type
                case isCancellation
            }

            let container = try decoder.container(keyedBy: Keys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "Transfer":
                self = try .transfer(Transfer(from: decoder))
            case "SettingsChange":
                self = try .settingsChange(SettingsChange(from: decoder))
            case "Custom":
                if let isCancellation = try container.decodeIfPresent(Bool.self, forKey: .isCancellation), isCancellation == true {
                    self = try .rejection(Rejection(from: decoder))
                } else {
                    self = try .custom(Custom(from: decoder))
                }
            case "Creation":
                self = try .creation(Creation(from: decoder))
            case "Unknown":
                fallthrough
            default:
                self = .unknown
            }
        }

        struct Transfer: Decodable {
            var sender: AddressString
            var senderInfo: AddressInfo?
            var recipient: AddressString
            var recipientInfo: AddressInfo?
            var direction: Direction
            var transferInfo: TransferInfo

            enum Direction: String, Decodable {
                case incoming = "INCOMING"
                case outgoing = "OUTGOING"
                case unknown = "UNKNOWN"
            }

            enum TransferInfo: Decodable {
                case erc20(Erc20)
                case erc721(Erc721)
                case ether(Ether)
                case unknown

                init(from decoder: Decoder) throws {
                    enum Keys: String, CodingKey { case type }
                    let container = try decoder.container(keyedBy: Keys.self)
                    let type = try container.decode(String.self, forKey: .type)

                    switch type {
                    case "ERC20":
                        self = try .erc20(Erc20(from: decoder))
                    case "ERC721":
                        self = try .erc721(Erc721(from: decoder))
                    case "ETHER":
                        self = try .ether(Ether(from: decoder))
                    default:
                        self = .unknown
                    }
                }

                struct Erc20: Decodable {
                    var tokenAddress: AddressString
                    var tokenName: String?
                    var tokenSymbol: String?
                    var logoUri: String?
                    var decimals: UInt64?
                    var value: UInt256String
                }

                struct Erc721: Decodable {
                    var tokenAddress: AddressString
                    var tokenId: UInt256String
                    var tokenName: String?
                    var tokenSymbol: String?
                    var logoUri: String?
                }

                struct Ether: Decodable {
                    var value: UInt256String
                }
            }
        }

        struct SettingsChange: Decodable {
            var dataDecoded: DataDecoded
            var settingsInfo: SettingsInfo

            enum SettingsInfo: Decodable {
                case setFallbackHandler(SetFallbackHandler)
                case addOwner(AddOwner)
                case removeOwner(RemoveOwner)
                case swapOwner(SwapOwner)
                case changeThreshold(ChangeThreshold)
                case changeImplementation(ChangeImplementation)
                case enableModule(EnableModule)
                case disableModule(DisableModule)
                case unknown

                init(from decoder: Decoder) throws {
                    enum Keys: String, CodingKey { case type }
                    let container = try decoder.container(keyedBy: Keys.self)
                    let type = try container.decode(String.self, forKey: .type)

                    switch type {
                    case "SET_FALLBACK_HANDLER":
                        self = try .setFallbackHandler(SetFallbackHandler(from: decoder))
                    case "ADD_OWNER":
                        self = try .addOwner(AddOwner(from: decoder))
                    case "REMOVE_OWNER":
                        self = try .removeOwner(RemoveOwner(from: decoder))
                    case "SWAP_OWNER":
                        self = try .swapOwner(SwapOwner(from: decoder))
                    case "CHANGE_THRESHOLD":
                        self = try .changeThreshold(ChangeThreshold(from: decoder))
                    case "CHANGE_IMPLEMENTATION":
                        self = try .changeImplementation(ChangeImplementation(from: decoder))
                    case "ENABLE_MODULE":
                        self = try .enableModule(EnableModule(from: decoder))
                    case "DISABLE_MODULE":
                        self = try .disableModule(DisableModule(from: decoder))
                    default:
                        self = .unknown
                    }
                }

                struct SetFallbackHandler: Decodable {
                    var handler: AddressString
                    var handlerInfo: AddressInfo?
                }

                struct AddOwner: Decodable {
                    var owner: AddressString
                    var ownerInfo: AddressInfo?
                    var threshold: UInt64
                }

                struct RemoveOwner: Decodable {
                    var owner: AddressString
                    var ownerInfo: AddressInfo?
                    var threshold: UInt64
                }

                struct SwapOwner: Decodable {
                    var newOwner: AddressString
                    var newOwnerInfo: AddressInfo?
                    var oldOwner: AddressString
                    var oldOwnerInfo: AddressInfo?
                }

                struct ChangeThreshold: Decodable {
                    var threshold: UInt64
                }

                struct ChangeImplementation: Decodable {
                    var implementation: AddressString
                    var implementationInfo: AddressInfo?
                }

                struct EnableModule: Decodable {
                    var module: AddressString
                    var moduleInfo: AddressInfo?
                }

                struct DisableModule: Decodable {
                    var module: AddressString
                    var moduleInfo: AddressInfo?
                }
            }
        }

        struct Custom: Decodable {
            var to: AddressString
            var toInfo: AddressInfo?
            var dataSize: UInt256String
            var value: UInt256String
            var methodName: String?
        }

        struct Rejection: Decodable {
            var to: AddressString
            var toInfo: AddressInfo?
            var dataSize: UInt256String
            var value: UInt256String
            var methodName: String?
        }

        struct Creation: Decodable {
            var creator: AddressString
            var transactionHash: DataString
            var implementation: AddressString?
            var factory: AddressString?
        }
    }

    struct DataDecoded: Decodable {
        var method: String
        var parameters: [Parameter]?

        struct Parameter: Decodable {
            var name: String
            var type: String
            var value: Value
            var valueDecoded: ValueDecoded?

            enum Value: Decodable {
                case string(String)
                case address(AddressString)
                case uint256(UInt256String)
                case data(DataString)
                case array([Value])
                case unknown

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()

                    if let string = try? container.decode(String.self) {

                        if string.hasPrefix("0x"), let address = try? container.decode(AddressString.self) {
                            self = .address(address)
                        } else if string.hasPrefix("0x"), let data = try? container.decode(DataString.self) {
                            self = .data(data)
                        } else if let uint256 = try? container.decode(UInt256String.self) {
                            self = .uint256(uint256)
                        } else {
                            self = .string(string)
                        }

                    } else if let array = try? container.decode([Value].self) {
                        self = .array(array)
                    } else {
                        self = .unknown
                    }
                }
            }

            enum ValueDecoded: Decodable {
                case multiSend([MultiSendTx])
                case unknown

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    if let multiSend = try? container.decode([MultiSendTx].self) {
                        self = .multiSend(multiSend)
                    } else {
                        self = .unknown
                    }
                }

                struct MultiSendTx: Decodable {
                    var operation: Operation
                    var to: AddressString
                    var value: UInt256String
                    var data: DataString
                    var dataDecoded: DataDecoded?
                }
                
            }
        }
    }

    struct TransactionDetails: Decodable {
        var txStatus: TxStatus
        var txInfo: TxInfo
        var txData: TxData?
        var detailedExecutionInfo: DetailedExecutionInfo?
        var txHash: DataString?
        var executedAt: Date?
        var safeAppInfo: SafeAppInfo?

        enum DetailedExecutionInfo: Decodable {
            case module(Module)
            case multisig(Multisig)
            case unknown

            init(from decoder: Decoder) throws {
                enum Keys: String, CodingKey { case type }
                let container = try decoder.container(keyedBy: Keys.self)
                let type = try container.decode(String.self, forKey: .type)

                switch type {
                case "MULTISIG":
                    self = try .multisig(Multisig(from: decoder))
                case "MODULE":
                    self = try .module(Module(from: decoder))
                default:
                    self = .unknown
                }
            }

            struct Module: Decodable {
                var address: AddressString
            }

            struct Multisig: Decodable {
                var safeTxGas: UInt256String
                var baseGas: UInt256String
                var gasPrice: UInt256String
                var gasToken: AddressString
                var refundReceiver: AddressString
                var safeTxHash: HashString
                var signers: [AddressString]
                var confirmationsRequired: UInt64
                var confirmations: [Confirmation]
                var rejectors: [AddressString]?
                var executor: AddressString?
                var submittedAt: Date
                var nonce: UInt256String
            }
        }
    }

    struct TxData: Decodable {
        var to: AddressString
        var value: UInt256String
        var operation: Operation
        var hexData: DataString?
        var dataDecoded: DataDecoded?
    }

    struct SafeAppInfo: Decodable {
        var name: String
        var url: String
        var logoUrl: String
    }

    enum Operation: Int, Codable {
        case call = 0
        case delegate = 1

        var data32: Data {
            UInt256(self.rawValue).data32
        }

        var name: String {
            switch self {
            case .call:
                return "call"
            case .delegate:
                return "delegateCall"
            }
        }
    }

    enum ConflictType: String, Decodable {
        case none = "None"
        case hasNext = "HasNext"
        case end = "End"
    }

    // MARK: - Safe Info Extended

    struct SafeInfoExtended: Decodable {
        var address: AddressInfoExtended
        var nonce: UInt256String
        var threshold: UInt256String
        var owners: [AddressInfoExtended]
        var implementation: AddressInfoExtended
        var modules: [AddressInfoExtended]?
        var fallbackHandler: AddressInfoExtended?
        var version: String
    }
}

extension SCGModels.AddressInfoExtended {
    var addressInfo: AddressInfo {
        .init(address: value.address, name: name, logoUri: logoUrl)
    }
}

extension SCGModels.AddressInfo {
    var addressInfo: AddressInfo {
        .init(address: .zero, name: name, logoUri: logoUri)
    }
}
