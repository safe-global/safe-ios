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

    static func exists(_ id: Int) throws -> Bool {
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

    static func by(_ id: Int) -> Network? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Network.fetchRequest().by(id: id)
        guard let chain = try? context.fetch(fr).first else { return nil }
        return chain
    }

    static func createOrUpdate(_ networkInfo: SCGModels.Network) -> Network {
        guard let chain = Network.by(networkInfo.chainId) else { return Network.create(networkInfo) }
        chain.update(from: networkInfo)
        return chain
    }

    @discardableResult
    static func create(chainId: Int,
                       chainName: String,
                       rpcUrl: URL,
                       blockExplorerUrl: URL,
                       currencyName: String,
                       currencySymbl: String,
                       currencyDecimals: Int,
                       themeTextColor: String,
                       themeBackgroundColor: String) -> Network {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let chain = Network(context: context)
        chain.chainId = Int32(chainId)
        chain.chainName = chainName
        chain.rpcUrl = rpcUrl
        chain.blockExplorerUrl = blockExplorerUrl

        let theme = NetworkTheme(context: context)
        theme.network = chain
        theme.textColor = themeTextColor
        theme.backgroundColor = themeBackgroundColor

        let token = NetworkToken(context: context)
        token.network = chain
        token.name = currencyName
        token.symbol = currencySymbl
        token.decimals = Int32(currencyDecimals)

        App.shared.coreDataStack.saveContext()

        return chain
    }

    @discardableResult
    static func create(_ networkInfo: SCGModels.Network) -> Network {
        Network.create(chainId: networkInfo.chainId,
                     chainName: networkInfo.chainName,
                     rpcUrl: networkInfo.rpcUrl,
                     blockExplorerUrl: networkInfo.blockExplorerUrl,
                     currencyName: networkInfo.nativeCurrency.name,
                     currencySymbl: networkInfo.nativeCurrency.symbol,
                     currencyDecimals: networkInfo.nativeCurrency.decimals,
                     themeTextColor: networkInfo.theme.textColor.description,
                     themeBackgroundColor: networkInfo.theme.backgroundColor.description)
    }

    static func updateIfExist(_ networkInfo: SCGModels.Network) {
        guard let network = Network.by(networkInfo.chainId) else { return }
        network.update(from: networkInfo)
    }

    static func remove(network: Network) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        context.delete(network)
        App.shared.coreDataStack.saveContext()
    }

    static func removeAll() throws {
        for network in all {
            remove(network: network)
        }
    }
}

extension Network {
    public var id: Int {
        Int(chainId)
    }

    func update(from networkInfo: SCGModels.Network) {
        chainId = chainId
        chainName = chainName
        rpcUrl = rpcUrl
        blockExplorerUrl = blockExplorerUrl
        theme?.textColor = networkInfo.theme.textColor.description
        theme?.backgroundColor = networkInfo.theme.backgroundColor.description
        nativeCurrency?.name = networkInfo.nativeCurrency.name
        nativeCurrency?.symbol = networkInfo.nativeCurrency.symbol
        nativeCurrency?.decimals = Int32(networkInfo.nativeCurrency.decimals)
    }

    func safes() -> [Safe] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Safe.fetchRequest().by(network: self))) ?? []
    }
}

extension NSFetchRequest where ResultType == Network {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Network.id, ascending: true)]
        return self
    }

    func by(id: Int) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chainId == %d", id)
        fetchLimit = 1
        return self
    }
}
