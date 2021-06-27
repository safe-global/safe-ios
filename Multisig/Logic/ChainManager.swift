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
        App.shared.clientGatewayService.chains { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chains):
                    for chain in chains {
                        Chain.updateIfExist(chain)
                    }
                    NotificationCenter.default.post(name: .networkInfoChanged, object: nil)
                case .failure(_):
                    // Failed to load chains
                    break
                }
            }
        }
    }
}
