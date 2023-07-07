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
        var transaction: TxSummary
        var conflictType: ConflictType
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
        var value: AddressString
        var name: String?
        var logoUri: URL?
    }

    /// This is a temporary solution for Known Addresses V3 before a proper refactoring with
    /// Known Addresses V4 is implemented.
    ///
    /// "addressInfoIndex": {
    ///   "0x8D29bE29923b68abfDD21e541b9374737B49cdAD": {
    ///     "name": "Gnosis Safe: Multi Send 1.1.1",
    ///     "logoUri": "https://safe-transaction-assets.staging.5afe.dev/contracts/logos/0x8D29bE29923b68abfDD21e541b9374737B49cdAD.png"
    ///   }
    /// }
    ///
    struct AddressInfoIndex: Decodable {
        var values: [AddressString: AddressInfo]

        init(from decoder: Decoder) throws {
            struct DynamicKey: CodingKey {
                var stringValue: String
                init?(stringValue: String) {
                    self.stringValue = stringValue
                }
                var intValue: Int?
                init?(intValue: Int) {
                    return nil
                }
            }

            values = [:]
            let container = try decoder.container(keyedBy: DynamicKey.self)
            try container.allKeys.forEach { key in
                let nameAndLogo = try container.decode(AddressInfo.self,
                                                       forKey: DynamicKey(stringValue: key.stringValue)!)
                guard let addressStr = AddressString(key.stringValue) else {
                    throw "Unexpected address format"
                }
                values[addressStr] = nameAndLogo
            }
        }
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
        // UI-only status when tx was submitted to the mempool(cgw status is AWAITING_EXECUTION)
        case pending = "PENDING"
    }

    enum ExecutionInfo: Decodable {
        case multisig(Multisig)
        case module(Module)
        case unknown

        init(from decoder: Decoder) throws {
            enum Keys: String, CodingKey {
                case type
            }

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

        struct Multisig: Decodable {
            var nonce: UInt256String
            var confirmationsRequired: UInt64
            var confirmationsSubmitted: UInt64
            var confirmations: [Confirmation]?
            var missingSigners: [AddressInfo]?
        }

        struct Module: Decodable {
            var address: AddressInfo
        }
    }

    struct Confirmation: Decodable {
        var signer: AddressInfo
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
            var sender: AddressInfo
            var recipient: AddressInfo
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
                case nativeCoin(NativeCoin)
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
                    case "NATIVE_COIN":
                        self = try .nativeCoin(NativeCoin(from: decoder))
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

                struct NativeCoin: Decodable {
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
                case setGuard(SetGuard)
                case deleteGuard
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
                    case "SET_GUARD":
                        self = try .setGuard(SetGuard(from: decoder))
                    case "DELETE_GUARD":
                        self = .deleteGuard
                    default:
                        self = .unknown
                    }
                }

                struct SetFallbackHandler: Decodable {
                    var handler: AddressInfo
                }

                struct AddOwner: Decodable {
                    var owner: AddressInfo
                    var threshold: UInt64
                }

                struct RemoveOwner: Decodable {
                    var owner: AddressInfo
                    var threshold: UInt64
                }

                struct SwapOwner: Decodable {
                    var newOwner: AddressInfo
                    var oldOwner: AddressInfo
                }

                struct ChangeThreshold: Decodable {
                    var threshold: UInt64
                }

                struct ChangeImplementation: Decodable {
                    var implementation: AddressInfo
                }

                struct EnableModule: Decodable {
                    var module: AddressInfo
                }

                struct DisableModule: Decodable {
                    var module: AddressInfo
                }

                struct SetGuard: Decodable {
                    var `guard`: AddressInfo
                }
            }
        }

        struct Custom: Decodable {
            var to: AddressInfo
            var dataSize: UInt256String
            var value: UInt256String
            var methodName: String?
            var actionCount: UInt256String?
        }

        struct Rejection: Decodable {
            var to: AddressInfo
            var dataSize: UInt256String
            var value: UInt256String
            var methodName: String?
            var actionCount: UInt256String?
        }

        struct Creation: Decodable {
            var creator: AddressInfo
            var transactionHash: DataString
            var implementation: AddressInfo?
            var factory: AddressInfo?
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
                    var value: UInt256String?
                    var data: DataString?
                    var dataDecoded: DataDecoded?
                }
                
            }
        }
    }

    struct TransactionDetails: Decodable {
        var txId: String
        var safeAddress: AddressString
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
                var address: AddressInfo
            }

            struct Multisig: Decodable {
                var safeTxGas: UInt256String
                var baseGas: UInt256String
                var gasPrice: UInt256String
                var gasToken: AddressString
                var refundReceiver: AddressInfo
                var safeTxHash: HashString
                var signers: [AddressInfo]
                var confirmationsRequired: UInt64
                var confirmations: [Confirmation]
                var rejectors: [AddressInfo]?
                var executor: AddressInfo?
                var submittedAt: Date
                var nonce: UInt256String
            }
        }
    }

    struct TrasactionPreview: Decodable {
        var txInfo: TxInfo
        var txData: TxData?
    }

    struct TxData: Decodable {
        var to: AddressInfo
        var value: UInt256String
        var operation: Operation
        var hexData: DataString?
        var dataDecoded: DataDecoded?
        var addressInfoIndex: AddressInfoIndex?
        var trustedDelegateCallTarget: Bool?
    }

    struct SafeAppInfo: Decodable {
        var name: String
        var url: String
        var logoUri: String
    }

    enum Operation: Int, Codable {
        case call = 0
        case delegate = 1

        var data32: Data {
            UInt256(self.rawValue).data32
        }

        var uint256: UInt256 {
            UInt256(self.rawValue)
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
        var address: AddressInfo
        var nonce: UInt256String
        var threshold: UInt256String
        var owners: [AddressInfo]
        var implementation: AddressInfo
        var modules: [AddressInfo]?
        var fallbackHandler: AddressInfo?
        var `guard`: AddressInfo?
        var version: String
        var implementationVersionState: ImplementationVersionState
    }

    enum ImplementationVersionState: String, Decodable {
        case upToDate = "UP_TO_DATE"
        case upgradeAvailable = "OUTDATED"
        case unknown = "UNKNOWN"
    }

    struct Chain: Decodable {
        let chainId: UInt256String
        let chainName: String
        let rpcUri: RpcAuthentication
        let blockExplorerUriTemplate: BlockExplorerUriTemplate
        let nativeCurrency: Currency
        let theme: Theme
        let ensRegistryAddress: AddressString?
        let shortName: String
        let l2: Bool
        let features: [String]
        let gasPrice: [GasPrice]

        var id: String {
            chainId.description
        }

        var authenticatedRpcUrl: URL {
            switch rpcUri.authentication {
            case .apiKeyPath:
                // assume for now that we're using INFURA API for every authenticated url
                return rpcUri.value.appendingPathComponent(App.configuration.services.infuraKey)
            case .none:
                return rpcUri.value
            }
        }

        var prefixString: String {
            AppSettings.prependingChainPrefixToAddresses ? "\(shortName):" : ""
        }

        func isSupported(feature: String) -> Bool {
            features.contains(feature)
        }
    }

    enum GasPrice: Decodable {
        case oracle(GasPriceOracle)
        case fixed(GasPriceFixed)
        case unknown

        init(from decoder: Decoder) throws {
            enum Keys: String, CodingKey { case type }
            let container = try decoder.container(keyedBy: Keys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "ORACLE":
                self = try .oracle(GasPriceOracle(from: decoder))
            case "FIXED":
                self = try .fixed(GasPriceFixed(from: decoder))
            default:
                self = .unknown
            }
        }
    }

    struct GasPriceOracle: Decodable {
        var uri: String
        var gasParameter: String
        var gweiFactor: String
    }

    struct GasPriceFixed: Decodable {
        var weiValue: String
    }

    struct RpcAuthentication: Codable {
        let authentication: Authentication
        let value: URL
        
        enum Authentication: String, Codable {
            // append the api key as a last path component of the uri
            case apiKeyPath = "API_KEY_PATH"
            // use uri as is
            case none = "NO_AUTHENTICATION"
        }
    }

    struct BlockExplorerUriTemplate: Codable {
        let address: String
        let txHash: String
    }

    struct Theme: Decodable {
        let textColor: String
        let backgroundColor: String
    }

    struct Currency: Decodable {
        let name: String
        let symbol: String
        let decimals: Int
        let logoUri: URL
    }

    struct TransactionEstimation: Decodable {
        let currentNonce: UInt256String
        let recommendedNonce: UInt256String
        let safeTxGas: String
    }

    struct KeyDelegate: Codable {
        var safe: AddressString?
        var delegate: AddressString
        var delegator: AddressString
        var label: String
    }

}

extension SCGModels.AddressInfo {
    var addressInfo: AddressInfo {
        .init(address: value.address, name: name, logoUri: logoUri)
    }
}

extension SCGModels.Chain {

    private static func createChainInfo(id: String,
                                        chainName: String,
                                        rpcUrl: URL,
                                        rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication = .apiKeyPath,
                                        blockExplorerUrlAddress: String,
                                        blockExplorerUrlTxHash: String,
                                        ensRegistryAddress: String,
                                        shortName: String,
                                        currencyName: String,
                                        currencySymbl: String,
                                        currencyDecimals: Int,
                                        currencyLogo: URL,
                                        themeTextColor: String,
                                        themeBackgroundColor: String) -> SCGModels.Chain {

        SCGModels.Chain(
            chainId: UInt256String(stringLiteral: id),
            chainName: chainName,
            rpcUri: SCGModels.RpcAuthentication(authentication: rpcUrlAuthentication, value: rpcUrl),
            blockExplorerUriTemplate: SCGModels.BlockExplorerUriTemplate(address: blockExplorerUrlAddress,
                                                                         txHash: blockExplorerUrlTxHash),
            nativeCurrency: SCGModels.Currency(name: currencyName,
                                               symbol: currencySymbl,
                                               decimals: currencyDecimals,
                                               logoUri: currencyLogo),
            theme: SCGModels.Theme(textColor: themeTextColor,
                                   backgroundColor: themeBackgroundColor),
            ensRegistryAddress: AddressString(ensRegistryAddress),
            shortName: shortName,
            l2: false,
            features: [],
            gasPrice: [])
    }

    static func mainnetChain() -> SCGModels.Chain {
        let chain = Chain.mainnetChain()
        return createChainInfo(
            id: chain.id!,
            chainName: chain.name!,
            rpcUrl: chain.rpcUrl!,
            blockExplorerUrlAddress: chain.blockExplorerUrlAddress!,
            blockExplorerUrlTxHash: chain.blockExplorerUrlTxHash!,
            ensRegistryAddress: chain.ensRegistryAddress!,
            shortName: chain.shortName!,
            currencyName: chain.nativeCurrency!.name!,
            currencySymbl: chain.nativeCurrency!.symbol!,
            currencyDecimals: Int(chain.nativeCurrency!.decimals),
            currencyLogo: chain.nativeCurrency!.logoUrl!,
            themeTextColor: chain.theme!.textColor!,
            themeBackgroundColor: chain.theme!.backgroundColor!
        )
    }

    static func rinkebyChain() -> SCGModels.Chain {
        let chain = Chain.rinkebyChain()
        return createChainInfo(
            id: chain.id!,
            chainName: chain.name!,
            rpcUrl: chain.rpcUrl!,
            blockExplorerUrlAddress: chain.blockExplorerUrlAddress!,
            blockExplorerUrlTxHash: chain.blockExplorerUrlTxHash!,
            ensRegistryAddress: chain.ensRegistryAddress!,
            shortName: chain.shortName!,
            currencyName: chain.nativeCurrency!.name!,
            currencySymbl: chain.nativeCurrency!.symbol!,
            currencyDecimals: Int(chain.nativeCurrency!.decimals),
            currencyLogo: chain.nativeCurrency!.logoUrl!,
            themeTextColor: chain.theme!.textColor!,
            themeBackgroundColor: chain.theme!.backgroundColor!
        )
    }
}

