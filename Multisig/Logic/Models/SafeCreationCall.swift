//
//  SafeCreationCall.swift
//  Multisig
//
//  Created by Moaaz on 2/25/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension SafeCreationCall {
    static func by(txHashes: [String], chainId: String) -> [SafeCreationCall]? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        return try? txHashes.compactMap { address in
            let fr = SafeCreationCall.fetchRequest().by(txHash: address, chainId: chainId)
            let items = try context.fetch(fr)
            return items.first
        }
    }

    static func by(safe: Safe) -> [SafeCreationCall] {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = SafeCreationCall.fetchRequest()
        fr.sortDescriptors = []
        fr.fetchLimit = 1
        fr.predicate = NSPredicate(format: "safeAddress = %@ AND chainId = %@", safe.address!, safe.chain!.id!)
        return (try? context.fetch(fr)) ?? []
    }
}


extension NSFetchRequest where ResultType == SafeCreationCall {
    func by(txHash: String, chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "transactionHash == %@ AND chainId == %@", txHash, chainId)
        fetchLimit = 1
        return self
    }
}
