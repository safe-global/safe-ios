//
//  Chain.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Chain {
    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Chain.fetchRequest().all())) ?? 0
    }

    static var all: [Chain] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Chain.fetchRequest().all())) ?? []
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
        guard let chain = Chain.by(chainInfo.chainId) else { return Chain.create(chainInfo) }
        chain.update(from: chainInfo)
        return chain
    }

    static func create(chainId: String,
                       chainName: String,
                       rpcUrl: String,
                       blockExplorerUrl: String,
                       currencyName: String,
                       currencySymbl: String,
                       currencyDecimals: Int,
                       transactionService: String,
                       themeTextColor: String,
                       themeBackgroundColor: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let chain = Chain(context: context)
        chain.chainId = chainId
        chain.chainName = chainName
        chain.rpcUrl = rpcUrl
        chain.blockExplorerUrl = blockExplorerUrl
        chain.transactionService = transactionService
        chain.theme = ChainTheme.create(textColor: themeTextColor, backgroundColor: themeBackgroundColor)
        chain.nativeCurrency = ChainToken.create(name: currencyName, symbol: currencySymbl, decimals: currencyDecimals)

        App.shared.coreDataStack.saveContext()
    }

    @discardableResult
    static func create(_ chainInfo: SCGModels.Chain) -> Chain {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let chain = Chain(context: context)
        chain.chainId = chainInfo.chainId
        chain.chainName = chainInfo.chainName
        chain.rpcUrl = chainInfo.rpcUrl
        chain.blockExplorerUrl = chainInfo.blockExplorerUrl
        chain.transactionService = chainInfo.transactionService
        chain.theme = ChainTheme.create(textColor: chainInfo.theme.textColor.description, backgroundColor: chainInfo.theme.backgroundColor.description)
        chain.nativeCurrency = ChainToken.create(name: chainInfo.nativeCurrency.name, symbol: chainInfo.nativeCurrency.symbol, decimals: chainInfo.nativeCurrency.decimals)

        App.shared.coreDataStack.saveContext()
        return chain
    }

    static func updateIfExist(_ chainInfo: SCGModels.Chain) {
        guard let chain = Chain.by(chainInfo.chainId) else { return }
        chain.update(from: chainInfo)
    }

    static func remove(chain: Chain) {
        let context = App.shared.coreDataStack.viewContext
        context.delete(chain)
        App.shared.coreDataStack.saveContext()
    }

    static func removeAll() throws {
        for chain in all {
            remove(chain: chain)
        }
    }
}

extension Chain {
    func update(from chain: SCGModels.Chain) {
        chainId = chainId
        chainName = chainName
        rpcUrl = rpcUrl
        blockExplorerUrl = blockExplorerUrl
        transactionService = transactionService
        theme?.update(textColor: chain.theme.textColor.description, backgroundColor: chain.theme.backgroundColor.description)
        nativeCurrency?.update(name: chain.nativeCurrency.name, symbol: chain.nativeCurrency.symbol, decimals: chain.nativeCurrency.decimals)
    }

    func safes() -> [Safe] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Safe.fetchRequest().by(chain: self))) ?? []
    }
}

extension NSFetchRequest where ResultType == Chain {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Chain.id, ascending: true)]
        return self
    }

    func by(id: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chainId == %@", id)
        fetchLimit = 1
        return self
    }
}
