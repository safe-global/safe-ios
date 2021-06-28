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

    static func exists(_ id: Int) throws -> Bool {
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

    static func by(_ id: Int) -> Chain? {
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

    @discardableResult
    static func create(chainId: Int,
                       chainName: String,
                       rpcUrl: URL,
                       blockExplorerUrl: URL,
                       currencyName: String,
                       currencySymbl: String,
                       currencyDecimals: Int,
                       themeTextColor: String,
                       themeBackgroundColor: String) -> Chain {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let chain = Chain(context: context)
        chain.chainId = Int32(chainId)
        chain.chainName = chainName
        chain.rpcUrl = rpcUrl
        chain.blockExplorerUrl = blockExplorerUrl

        let theme = ChainTheme(context: context)
        theme.chain = chain
        theme.textColor = themeTextColor
        theme.backgroundColor = themeBackgroundColor

        let token = ChainToken(context: context)
        token.chain = chain
        token.name = currencyName
        token.symbol = currencySymbl
        token.decimals = Int32(currencyDecimals)

        App.shared.coreDataStack.saveContext()

        return chain
    }

    @discardableResult
    static func create(_ chainInfo: SCGModels.Chain) -> Chain {
        Chain.create(chainId: chainInfo.chainId,
                     chainName: chainInfo.chainName,
                     rpcUrl: chainInfo.rpcUrl,
                     blockExplorerUrl: chainInfo.blockExplorerUrl,
                     currencyName: chainInfo.nativeCurrency.name,
                     currencySymbl: chainInfo.nativeCurrency.symbol,
                     currencyDecimals: chainInfo.nativeCurrency.decimals,
                     themeTextColor: chainInfo.theme.textColor.description,
                     themeBackgroundColor: chainInfo.theme.backgroundColor.description)
    }

    static func updateIfExist(_ chainInfo: SCGModels.Chain) {
        guard let chain = Chain.by(chainInfo.chainId) else { return }
        chain.update(from: chainInfo)
    }

    static func remove(chain: Chain) {
        dispatchPrecondition(condition: .onQueue(.main))
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
        theme?.textColor = chain.theme.textColor.description
        theme?.backgroundColor = chain.theme.backgroundColor.description
        nativeCurrency?.name = chain.nativeCurrency.name
        nativeCurrency?.symbol = chain.nativeCurrency.symbol
        nativeCurrency?.decimals = Int32(chain.nativeCurrency.decimals)
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

    func by(id: Int) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chainId == %d", id)
        fetchLimit = 1
        return self
    }
}
