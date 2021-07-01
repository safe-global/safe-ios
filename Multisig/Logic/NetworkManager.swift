//
//  ChainManager.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class NetworkManager {
    static func updateChainsInfo() {
        App.shared.clientGatewayService.asyncNetworks { result in
            DispatchQueue.main.async {
                switch result {
                    for network in networks.results {
                case .success(let networks):
                        Network.updateIfExist(network)
                    }
                    NotificationCenter.default.post(name: .networkInfoChanged, object: nil)
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

        let notMigrated = allSafes.filter { $0.network == nil }
        if notMigrated.isEmpty { return }

        let mainnet = Network.mainnetChain()
        for safe in notMigrated {
            safe.network = mainnet
        }
        App.shared.coreDataStack.saveContext()
    }
}
