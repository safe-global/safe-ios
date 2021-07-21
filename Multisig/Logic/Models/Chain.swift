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

    static func createOrUpdate(_ networkInfo: SCGModels.Network) -> Chain {
        guard let chain = Chain.by(networkInfo.id) else {
            // should not fail, otherwise programmer error
            return try! Chain.create(networkInfo)
        }
        // can't fail because chain id is correct
        try! chain.update(from: networkInfo)
        return chain
    }

    @discardableResult
    static func create(chainId: String,
                       chainName: String,
                       rpcUrl: URL,
                       blockExplorerUrl: URL,
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
        chain.blockExplorerUrl = blockExplorerUrl
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
    static func create(_ networkInfo: SCGModels.Network) throws -> Chain {
        try Chain.create(chainId: networkInfo.id,
                         chainName: networkInfo.chainName,
                         rpcUrl: networkInfo.rpcUri,
                         blockExplorerUrl: networkInfo.blockExplorerUri,
                         ensRegistryAddress: networkInfo.ensRegistryAddress?.description,
                         currencyName: networkInfo.nativeCurrency.name,
                         currencySymbl: networkInfo.nativeCurrency.symbol,
                         currencyDecimals: networkInfo.nativeCurrency.decimals,
                         currencyLogo: networkInfo.nativeCurrency.logoUri,
                         themeTextColor: networkInfo.theme.textColor.description,
                         themeBackgroundColor: networkInfo.theme.backgroundColor.description)
    }

    static func updateIfExist(_ networkInfo: SCGModels.Network) {
        guard let network = Chain.by(networkInfo.chainId.description) else { return }
        try! network.update(from: networkInfo)
    }

    static func remove(network: Chain) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        context.delete(network)
        App.shared.coreDataStack.saveContext()
    }

    static func removeAll() {
        for network in all {
            remove(network: network)
        }
    }
}

extension Chain {
    func update(from networkInfo: SCGModels.Network) throws {
        guard id == networkInfo.id else {
            throw GSError.NetworkIdMismatch()
        }

        name =  networkInfo.chainName
        rpcUrl = networkInfo.rpcUri
        blockExplorerUrl = networkInfo.blockExplorerUri
        ensRegistryAddress = networkInfo.ensRegistryAddress?.description

        theme?.textColor = networkInfo.theme.textColor
        theme?.backgroundColor = networkInfo.theme.backgroundColor

        nativeCurrency?.name = networkInfo.nativeCurrency.name
        nativeCurrency?.symbol = networkInfo.nativeCurrency.symbol
        nativeCurrency?.decimals = Int32(networkInfo.nativeCurrency.decimals)
        nativeCurrency?.logoUrl = networkInfo.nativeCurrency.logoUri
    }
}

extension NSFetchRequest where ResultType == Chain {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Chain.id, ascending: true)]
        return self
    }

    func by(id: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "id == %@", id)
        fetchLimit = 1
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
            blockExplorerUrl: URL(string: "https://etherscan.io/")!,
            ensRegistryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
            currencyName: "Ether",
            currencySymbl: "ETH",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/ethereum-eth-logo.png")!,
            themeTextColor: "#001428",
            themeBackgroundColor: "#E8E7E6")
    }

    typealias ChainSafes = [(chain: Chain, safes: [Safe])]

    /// Returns safes grouped by network with the following logic applied:
    /// - Selected safe network will be first in the list
    /// - Other networks are sorted by network id
    /// - Selected safe will be the first in the list of network safes. Other safes are sorted by addition date with earlist on top.
    static func chainSafes() -> ChainSafes {
        guard let safes = try? Safe.getAll(),
              let selectedSafe = safes.first(where: { $0.isSelected }),
              let selectedSafeChain = selectedSafe.chain else { return [] }

        var chainSafes = ChainSafes()
        let groupedSafes = Dictionary(grouping: safes, by: {$0.chain!})

        // Add selected safe Network on top with selected safe on top within the group
        let selectedSafeChainOtherSafes = groupedSafes[selectedSafeChain]!
            .filter { !$0.isSelected }
            .sorted { $0.additionDate! > $1.additionDate! }
        chainSafes.append((chain: selectedSafeChain, safes: [selectedSafe] + selectedSafeChainOtherSafes))

        // Add other networks sorted by id with safes sorted by most recently added
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
