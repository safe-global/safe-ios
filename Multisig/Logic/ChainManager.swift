//
//  ChainManager.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class ChainManager {
    static func updateChainsInfo() {
        App.shared.clientGatewayService.asyncChains { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chains):
                    for chain in chains.results { Chain.createOrUpdate(chain) }
                    NotificationCenter.default.post(name: .chainInfoChanged, object: nil)
                case .failure(_):
                    // Ignoring error because we'll try again in the next app start.
                    break
                }
            }
        }
    }

    // prior 2.19.0 safes did not have attached networks
    static func migrateOldSafes() {
        guard let allSafes = try? Safe.getAll() else { return }

        let notMigrated = allSafes.filter { $0.chain == nil }
        if notMigrated.isEmpty { return }

        let mainnet = Chain.mainnetChain()
        for safe in notMigrated {
            safe.chain = mainnet
        }
        App.shared.coreDataStack.saveContext()
    }
}
