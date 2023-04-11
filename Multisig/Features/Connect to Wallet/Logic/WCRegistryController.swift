//
//  WCRegistryController.swift
//  Multisig
//
//  Created by Vitaly on 10.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

protocol WCRegistryControllerDelegate: AnyObject {
    func didUpdate(controller: WCRegistryController)
    func didFailToLoad(controller: WCRegistryController, error: Error)
}

class WCRegistryController {

    // using wallet ids for keeping ranked order is hard to maintain
    // thus using wallet names
    static let popularWallets = [
        "Rainbow",
        "Trust Wallet",
        "Argent",
        "MetaMask",
        "Crypto.com | DeFi Wallet",
        "Pillar",
        "imToken",
        "ONTO",
        "TokenPocket"
    ]

    static let excludedWallets = [
        // excluded because it's this app
        "Gnosis Safe Multisig",
        "Safe",
        "Safe Multisig"
    ]

    weak var delegate: WCRegistryControllerDelegate?

    var repository = WCAppRegistryRepository()

    func loadData() {
        _ = App.shared.walletConnectRegistryService.asyncWallets { [weak self] result in
            guard let self = self else {
                return
            }
            // FIXME: Use background core data context in order to save in background
            DispatchQueue.main.async {
                switch (result) {
                case .success(let registry):
                    self.updateEntries(registry: registry)
                    self.delegate?.didUpdate(controller: self)

                case .failure(let error):
                    self.delegate?.didFailToLoad(controller: self, error: error)
                }
            }
        }
    }

    func updateEntries(registry: JsonAppRegistry) {
        let entries: [WCAppRegistryEntry] = registry.entries.values
                .filter {
                    !Self.excludedWallets.contains($0.name)
                }
                .compactMap { entry in
                    // currently elements are coming not sorted from wc registry json
                    // we define custom ranking for sorting by most popular wallets first
                    let popularWalletIndex = Self.popularWallets.firstIndex(of: entry.name) ?? Int.max
                    return self.repository.entry(from: entry, role: .wallet, rank: popularWalletIndex)
                }

        repository.updateEntries(entries)
    }


    // retrieve wallets from db
    func wallets(_ searchTerm: String? = nil) -> [WCAppRegistryEntry] {
        repository.entries(searchTerm: searchTerm, role: .wallet)
    }
}
