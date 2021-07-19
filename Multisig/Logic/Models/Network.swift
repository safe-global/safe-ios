//
//  Chain.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Network {
    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Network.fetchRequest().all())) ?? 0
    }

    static var all: [Network] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Network.fetchRequest().all())) ?? []
    }

    static var nativeCoin: NetworkToken? {
        (try? Safe.getSelected())?.network?.nativeCurrency
    }

    static func exists(_ id: String) throws -> Bool {
        do {
            dispatchPrecondition(condition: .onQueue(.main))
            let context = App.shared.coreDataStack.viewContext
            let fr = Network.fetchRequest().by(id: id)
            let count = try context.count(for: fr)
            return count > 0
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func by(_ id: String) -> Network? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Network.fetchRequest().by(id: id)
        guard let chain = try? context.fetch(fr).first else { return nil }
        return chain
    }

    static func createOrUpdate(_ networkInfo: SCGModels.Network) -> Network {
        guard let chain = Network.by(networkInfo.id) else {
            // should not fail, otherwise programmer error
            return try! Network.create(networkInfo)
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
                       themeBackgroundColor: String) throws -> Network {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let network = Network(context: context)
        network.chainId = chainId
        network.chainName = chainName
        network.rpcUrl = rpcUrl
        network.blockExplorerUrl = blockExplorerUrl
        network.ensRegistryAddress = ensRegistryAddress

        let theme = NetworkTheme(context: context)
        theme.textColor = themeTextColor
        theme.backgroundColor = themeBackgroundColor
        theme.network = network

        let token = NetworkToken(context: context)
        token.name = currencyName
        token.symbol = currencySymbl
        token.decimals = Int32(currencyDecimals)
        token.network = network
        token.logoUrl = currencyLogo

        try App.shared.coreDataStack.viewContext.save()

        return network
    }

    @discardableResult
    static func create(_ networkInfo: SCGModels.Network) throws -> Network {
        try Network.create(chainId: networkInfo.id,
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
        guard let network = Network.by(networkInfo.chainId.description) else { return }
        try! network.update(from: networkInfo)
    }

    static func remove(network: Network) {
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

extension Network {
    func update(from networkInfo: SCGModels.Network) throws {
        guard chainId == networkInfo.id else {
            throw GSError.NetworkIdMismatch()
        }

        chainName =  networkInfo.chainName
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

extension NSFetchRequest where ResultType == Network {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Network.chainId, ascending: true)]
        return self
    }

    func by(id: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chainId == %@", id)
        fetchLimit = 1
        return self
    }
}

extension Network {
    enum ChainID {
        static let ethereumMainnet = "1"
        static let ethereumRinkeby = "4"
        static let polygon = "137"
        static let xDai = "100"
    }

    static func mainnetChain() -> Network {
        try! Network.by(ChainID.ethereumMainnet) ?? Network.create(
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

    typealias NetworkSafes = [(network: Network, safes: [Safe])]

    /// Returns safes grouped by network with the following logic applied:
    /// - Selected safe network will be first in the list
    /// - Other networks are sorted by network id
    /// - Selected safe will be the first in the list of network safes. Other safes are sorted by addition date with earlist on top.
    static func networkSafes() -> NetworkSafes {
        guard let safes = try? Safe.getAll(),
              let selectedSafe = safes.first(where: { $0.isSelected }),
              let selectedSafeNetwork = selectedSafe.network else { return [] }

        var networkSafes = NetworkSafes()
        let groupedSafes = Dictionary(grouping: safes, by: {$0.network!})

        // Add selected safe Network on top with selected safe on top within the group
        let selectedSafeNetworkOtherSafes = groupedSafes[selectedSafeNetwork]!
            .filter { !$0.isSelected }
            .sorted { $0.additionDate! > $1.additionDate! }
        networkSafes.append((network: selectedSafeNetwork, safes: [selectedSafe] + selectedSafeNetworkOtherSafes))

        // Add other networks sorted by id with safes sorted by most recently added
        groupedSafes.keys
            .filter { $0 != selectedSafeNetwork }
            .sorted { UInt256($0.chainId!)! < UInt256($1.chainId!)! }
            .forEach { network in
                networkSafes.append(
                    (network: network,
                     safes: groupedSafes[network]!.sorted { $0.additionDate! > $1.additionDate!})
                )
            }

        return networkSafes
    }
}

extension Network {
    var authenticatedRpcUrl: URL {
        rpcUrl!.appendingPathComponent(App.configuration.services.infuraKey)
    }
}
