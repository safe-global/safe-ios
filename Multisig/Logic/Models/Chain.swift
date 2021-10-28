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

        theme?.textColor = chainInfo.theme.textColor
        theme?.backgroundColor = chainInfo.theme.backgroundColor

        nativeCurrency?.name = chainInfo.nativeCurrency.name
        nativeCurrency?.symbol = chainInfo.nativeCurrency.symbol
        nativeCurrency?.decimals = Int32(chainInfo.nativeCurrency.decimals)
        nativeCurrency?.logoUrl = chainInfo.nativeCurrency.logoUri
    }
}

extension NSFetchRequest where ResultType == Chain {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Chain.id, ascending: true)]
        return self
    }
}

extension Chain {
    enum ChainID {
        static let ethereumMainnet = "1"
        static let ethereumRinkeby = "4"
        static let polygon = "137"
        static let xDai = "100"
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
            currencyName: "Ether",
            currencySymbl: "ETH",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/ethereum-eth-logo.png")!,
            themeTextColor: "#001428",
            themeBackgroundColor: "#E8E7E6")
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

    typealias ChainEntities = [(chain: Chain, entities: [AddressBookEntity])]

    /// Returns safes grouped by chain with the following logic applied:
    /// - Selected safe chain will be first in the list
    /// - Other chains are sorted by chain id
    /// - Selected safe will be the first in the list of chain safes. Other safes are sorted by addition date with earlist on top.
    static func chainEntities() -> ChainEntities {
        guard let entities = try? AddressBookEntity.getAll() else { return [] }

        var chainEntities = ChainEntities()
        let groupedEntities = Dictionary(grouping: entities, by: {$0.chain!})

        groupedEntities.keys
            .sorted { UInt256($0.id!)! < UInt256($1.id!)! }
            .forEach { chain in
                chainEntities.append(
                    (chain: chain,
                     entities: groupedEntities[chain]!.sorted { $0.additionDate! > $1.additionDate!})
                )
            }

        return chainEntities
    }
}

extension Chain {
    var authenticatedRpcUrl: URL {
        rpcUrl!.appendingPathComponent(App.configuration.services.infuraKey)
    }

    var textColor: UIColor? {
        theme?.textColor.flatMap(UIColor.init(hex:))
    }

    var backgroundColor: UIColor? {
        theme?.backgroundColor.flatMap(UIColor.init(hex:))
    }
}
