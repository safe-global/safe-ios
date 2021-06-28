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
        App.shared.clientGatewayService.networks { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let networks):
                    for network in networks {
                        Network.updateIfExist(network)
                    }
                    NotificationCenter.default.post(name: .networkInfoChanged, object: nil)
                case .failure(_):
                    // Failed to load chains
                    break
                }
            }
        }
    }

    // prior 2.19.0 safes did not have attached networks
    static func migrateOldSafes() {
        let safes = try! Safe.getAll()
        safes.forEach { safe in
            if safe.network == nil {
                safe.network = mainnetChain()
                App.shared.coreDataStack.saveContext()
            }
        }
    }

    #warning("TODO: double check when production parameters are ready")
    static func mainnetChain() -> Network {
        Network.by(1) ?? Network.create(
            chainId: 1,
            chainName: "Main Ethereum Network",
            rpcUrl: App.configuration.services.ethereumServiceURL,
            blockExplorerUrl: App.configuration.services.etehreumBlockBrowserURL,
            currencyName: "Ether",
            currencySymbl: "ETH",
            currencyDecimals: 18,
            themeTextColor: "#fff",
            themeBackgroundColor: "#000")
    }
}
