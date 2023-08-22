//
//  Chain.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Chain {
    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Chain.fetchRequest().all())) ?? 0
    }

    static var all: [Chain] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Chain.fetchRequest().all())) ?? []
    }

    static var nativeCoin: ChainToken? {
        (try? Safe.getSelected())?.chain?.nativeCurrency
    }

    static func exists(_ id: String) throws -> Bool {
        do {
            dispatchPrecondition(condition: .onQueue(.main))
            let context = App.shared.coreDataStack.viewContext
            let fr = Chain.fetchRequest().by(id: id)
            let count = try context.count(for: fr)
            return count > 0
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func by(_ id: String) -> Chain? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Chain.fetchRequest().by(id: id)
        guard let chain = try? context.fetch(fr).first else { return nil }
        return chain
    }

    static func by(shortName: String) -> Chain? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Chain.fetchRequest().by(shortName: shortName)
        guard let chain = try? context.fetch(fr).first else { return nil }
        return chain
    }

    @discardableResult
    static func createOrUpdate(_ chainInfo: SCGModels.Chain) -> Chain {
        guard let chain = Chain.by(chainInfo.id) else {
            // should not fail, otherwise programmer error
            return try! Chain.create(chainInfo)
        }
        // can't fail because chain id is correct
        try! chain.update(from: chainInfo)
        return chain
    }

    @discardableResult
    static func create(chainId: String,
                       chainName: String,
                       rpcUrl: URL,
                       rpcUrlAuthentication: String,
                       blockExplorerUrlAddress: String,
                       blockExplorerUrlTxHash: String,
                       ensRegistryAddress: String?,
                       shortName: String,
                       currencyName: String,
                       currencySymbl: String,
                       currencyDecimals: Int,
                       currencyLogo: URL,
                       themeTextColor: String,
                       themeBackgroundColor: String) throws -> Chain {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let chain = Chain(context: context)
        chain.id = chainId
        chain.name = chainName
        chain.rpcUrl = rpcUrl
        chain.rpcUrlAuthentication = rpcUrlAuthentication
        chain.blockExplorerUrlAddress = blockExplorerUrlAddress
        chain.blockExplorerUrlTxHash = blockExplorerUrlTxHash
        chain.ensRegistryAddress = ensRegistryAddress
        chain.shortName = shortName

        let theme = ChainTheme(context: context)
        theme.textColor = themeTextColor
        theme.backgroundColor = themeBackgroundColor
        theme.chain = chain

        let token = ChainToken(context: context)
        token.name = currencyName
        token.symbol = currencySymbl
        token.decimals = Int32(currencyDecimals)
        token.chain = chain
        token.logoUrl = currencyLogo

        try App.shared.coreDataStack.viewContext.save()

        return chain
    }

    @discardableResult
    static func create(_ chainInfo: SCGModels.Chain) throws -> Chain {
        try Chain.create(chainId: chainInfo.id,
                         chainName: chainInfo.chainName,
                         rpcUrl: chainInfo.rpcUri.value,
                         rpcUrlAuthentication: chainInfo.rpcUri.authentication.rawValue,
                         blockExplorerUrlAddress: chainInfo.blockExplorerUriTemplate.address,
                         blockExplorerUrlTxHash: chainInfo.blockExplorerUriTemplate.txHash,
                         ensRegistryAddress: chainInfo.ensRegistryAddress?.description,
                         shortName: chainInfo.shortName,
                         currencyName: chainInfo.nativeCurrency.name,
                         currencySymbl: chainInfo.nativeCurrency.symbol,
                         currencyDecimals: chainInfo.nativeCurrency.decimals,
                         currencyLogo: chainInfo.nativeCurrency.logoUri,
                         themeTextColor: chainInfo.theme.textColor.description,
                         themeBackgroundColor: chainInfo.theme.backgroundColor.description)
    }

    static func updateIfExist(_ chainInfo: SCGModels.Chain) {
        guard let chain = Chain.by(chainInfo.chainId.description) else { return }
        try! chain.update(from: chainInfo)
    }

    static func remove(chain: Chain) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        context.delete(chain)
        App.shared.coreDataStack.saveContext()
    }

    static func removeAll() {
        for chain in all {
            remove(chain: chain)
        }
    }
}

extension Chain {
    func update(from chainInfo: SCGModels.Chain) throws {
        guard id == chainInfo.id else {
            throw GSError.ChainIdMismatch()
        }

        name =  chainInfo.chainName
        rpcUrl = chainInfo.rpcUri.value
        rpcUrlAuthentication = chainInfo.rpcUri.authentication.rawValue
        blockExplorerUrlAddress = chainInfo.blockExplorerUriTemplate.address
        blockExplorerUrlTxHash = chainInfo.blockExplorerUriTemplate.txHash
        ensRegistryAddress = chainInfo.ensRegistryAddress?.description
        shortName = chainInfo.shortName

        theme?.textColor = chainInfo.theme.textColor
        theme?.backgroundColor = chainInfo.theme.backgroundColor

        nativeCurrency?.name = chainInfo.nativeCurrency.name
        nativeCurrency?.symbol = chainInfo.nativeCurrency.symbol
        nativeCurrency?.decimals = Int32(chainInfo.nativeCurrency.decimals)
        nativeCurrency?.logoUrl = chainInfo.nativeCurrency.logoUri

        l2 = chainInfo.l2
        features = chainInfo.features
        gasPrice = chainInfo.gasPrice
    }

    var gasPrice: [SCGModels.GasPrice] {
        get {
            guard let sources = gasPriceSource else { return [] }
            return sources.compactMap { element -> SCGModels.GasPrice? in
                guard let source = element as? ChainGasPriceSource else { return nil }
                switch source.sourceType {
                case "ORACLE":
                    guard let uri = source.uri,
                          let gasParameter = source.gasParameter,
                          let gweiFactor = source.gweiFactor
                    else {
                        return nil
                    }
                    return .oracle(SCGModels.GasPriceOracle(uri: uri, gasParameter: gasParameter, gweiFactor: gweiFactor))

                case "FIXED":
                    guard let weiValue = source.weiValue else { return nil }
                    return .fixed(SCGModels.GasPriceFixed(weiValue: weiValue))

                default:
                    return .unknown
                }
            }
        }
        set {
            let newSources = newValue.compactMap { gasPrice -> ChainGasPriceSource? in
                guard let context = self.managedObjectContext else { return nil }

                let value = ChainGasPriceSource(context: context)

                switch gasPrice {
                case .oracle(let oracle):
                    value.sourceType = "ORACLE"
                    value.uri = oracle.uri
                    value.gasParameter = oracle.gasParameter
                    value.gweiFactor = oracle.gweiFactor

                case .fixed(let fixed):
                    value.sourceType = "FIXED"
                    value.weiValue = fixed.weiValue

                case .unknown:
                    value.sourceType = "UNKNOWN"
                }
                return value
            }
            if let existing = gasPriceSource {
                removeFromGasPriceSource(existing)
            }
            addToGasPriceSource(NSOrderedSet(array: newSources))
        }
    }

    var features: [String]? {
        get {
            featuresCommaSeparated?.split(separator: ",").map(String.init)
        }
        set {
            featuresCommaSeparated = newValue?.joined(separator: ",")
        }
    }

    func browserURL(address: String) -> URL {
        guard let addressUrlTemplate = blockExplorerUrlAddress
        else {
            assertionFailure("Block explorer url called when no chain's blockExplorerUrlAddress found")
            return App.configuration.services.webAppURL
        }
        return URL(string: addressUrlTemplate.replacingOccurrences(of: "{{address}}", with: address))!
    }
    
    func browserURL(txHash: String) -> URL {
        guard let txHashUrlTemplate = blockExplorerUrlTxHash
        else {
            assertionFailure("Block explorer url called when no chain's blockExplorerUrlTxHash found")
            return App.configuration.services.webAppURL
        }
        return URL(string: txHashUrlTemplate.replacingOccurrences(of: "{{txHash}}", with: txHash))!
    }
}

extension NSFetchRequest where ResultType == Chain {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Chain.id, ascending: true)]
        return self
    }

    func by(shortName: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "shortName == %@", shortName)
        fetchLimit = 1
        return self
    }
}

extension Chain {
    enum ChainID {
        static let ethereumMainnet = "1"
        static let ethereumRinkeby = "4"
        static let polygon = "137"
        static let gnosis = "100"
        static let bsc = "56"
        static let arbitrum = "42161"
        static let avalanche = "43114"
        static let optimism = "10"
        static let goerli = "5"
    }

    static func mainnetChain() -> Chain {
        try! Chain.by(ChainID.ethereumMainnet) ?? Chain.create(
            chainId: ChainID.ethereumMainnet,
            chainName: "Mainnet",
            rpcUrl: URL(string: "https://mainnet.infura.io/v3/")!,
            rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication.apiKeyPath.rawValue,
            blockExplorerUrlAddress: "https://etherscan.io/address/{{address}}",
            blockExplorerUrlTxHash: "https://etherscan.io/tx/{{txHash}}",
            ensRegistryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
            shortName: "eth",
            currencyName: "Ether",
            currencySymbl: "ETH",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/ethereum-eth-logo.png")!,
            themeTextColor: "#001428",
            themeBackgroundColor: "#E8E7E6")
    }

    static func rinkebyChain() -> Chain {
        try! Chain.by(ChainID.ethereumRinkeby) ?? Chain.create(
            chainId: ChainID.ethereumRinkeby,
            chainName: "Rinkeby",
            rpcUrl: URL(string: "https://rinkeby.infura.io/v3/")!,
            rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication.apiKeyPath.rawValue,
            blockExplorerUrlAddress: "https://rinkeby.etherscan.io/address/{{address}}",
            blockExplorerUrlTxHash: "https://rinkeby.etherscan.io/tx/{{txHash}}",
            ensRegistryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
            shortName: "rin",
            currencyName: "Ether",
            currencySymbl: "ETH",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://safe-transaction-assets.staging.5afe.dev/chains/4/currency_logo.png")!,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#E8673C")
    }
    
    static func goerliChain() -> Chain {
        try! Chain.by(ChainID.goerli) ?? Chain.create(
            chainId: ChainID.goerli,
            chainName: "Base Goerli Testnet",
            rpcUrl: URL(string: "https://goerli.base.org")!,
            rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication.none.rawValue,
            blockExplorerUrlAddress: "https://goerli.basescan.org/address/{{address}}",
            blockExplorerUrlTxHash: "https://goerli.basescan.org/tx/{{txHash}}",
            ensRegistryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
            shortName: "gor",
            currencyName: "Goerli Ether",
            currencySymbl: "GOR",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://safe-transaction-assets.safe.global/chains/5/currency_logo.png")!,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#4D99EB")
    }

    typealias ChainSafes = [(chain: Chain, safes: [Safe])]

    /// Returns safes grouped by chain with the following logic applied:
    /// - Selected safe chain will be first in the list
    /// - Other chains are sorted by chain id
    /// - Selected safe will be the first in the list of chain safes. Other safes are sorted by addition date with earlist on top.
    static func chainSafes() -> ChainSafes {
        guard let safes = try? Safe.getAll(),
              let selectedSafe = safes.first(where: { $0.isSelected }),
              let selectedSafeChain = selectedSafe.chain else { return [] }

        var chainSafes = ChainSafes()
        let groupedSafes = Dictionary(grouping: safes, by: {$0.chain!})

        // Add selected safe chain on top with selected safe on top within the group
        let selectedSafeChainOtherSafes = groupedSafes[selectedSafeChain]!
            .filter { !$0.isSelected }
            .sorted { $0.additionDate! > $1.additionDate! }
        chainSafes.append((chain: selectedSafeChain, safes: [selectedSafe] + selectedSafeChainOtherSafes))

        // Add other chains sorted by id with safes sorted by most recently added
        groupedSafes.keys
            .filter { $0 != selectedSafeChain }
            .sorted { UInt256($0.id!)! < UInt256($1.id!)! }
            .forEach { chain in
                chainSafes.append(
                    (chain: chain,
                     safes: groupedSafes[chain]!.sorted { $0.additionDate! > $1.additionDate!})
                )
            }

        return chainSafes
    }

    typealias ChainEntries = [(chain: Chain, entries: [AddressBookEntry])]

    /// Returns safes grouped by chain sorted by chain id
    static func chainEntries() -> ChainEntries {
        guard let entries = try? AddressBookEntry.getAll() else { return [] }

        var chainEntries = ChainEntries()
        let groupedEntries = Dictionary(grouping: entries, by: {$0.chain!})

        groupedEntries.keys
            .sorted { UInt256($0.id!)! < UInt256($1.id!)! }
            .forEach { chain in
                chainEntries.append(
                    (chain: chain,
                     entries: groupedEntries[chain]!.sorted { $0.name! < $1.name! })
                )
            }

        return chainEntries
    }
}

extension Chain {
    var authenticatedRpcUrl: URL {
        switch self.rpcUrlAuthentication {
        case SCGModels.RpcAuthentication.Authentication.apiKeyPath.rawValue:
            return rpcUrl!.appendingPathComponent(App.configuration.services.infuraKey)
        default:
            return rpcUrl!
        }
    }

    var textColor: UIColor? {
        theme?.textColor.flatMap(UIColor.init(hex:))
    }

    var backgroundColor: UIColor? {
        theme?.backgroundColor.flatMap(UIColor.init(hex:))
    }
}

extension Chain {
    enum Feature: String {
        case contractInteraction = "CONTRACT_INTERACTION"
        case defaultTokenList = "DEFAULT_TOKENLIST"
        case domainLookup = "DOMAIN_LOOKUP"
        case eip1271 = "EIP1271"
        case eip1559 = "EIP1559"
        case erc721 = "ERC721"
        case relayingMobile = "RELAYING_MOBILE"
        case web3authCreateSafe = "WEB3AUTH_CREATE_SAFE"
        case safeApps = "SAFE_APPS"
        case safeTxGasOptional = "SAFE_TX_GAS_OPTIONAL"
        case spendingLimit = "SPENDING_LIMIT"
        case txSimulation = "TX_SIMULATION"
        case warningBanner = "WARNING_BANNER"
        case moonpay = "MOONPAY_MOBILE"
    }

    var enabledFeatures: [Feature] {
        features?.compactMap { feature in
            Feature(rawValue: feature.uppercased())
        } ?? []
    }

    func isSupported(feature: Feature) -> Bool {
        AppConfiguration.FeatureToggles.relay && enabledFeatures.contains(feature)
    }
}
