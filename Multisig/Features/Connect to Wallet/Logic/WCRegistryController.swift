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
                    let entries = registry.entries.values.compactMap { entry in
                        
                        // currently elements are coming not sorted from wc registry json
                        self.repository.entry(from: entry, role: .wallet, rank: 0)
                    }
                    // TODO: define custom ranking for sorting by most popular wallets first
                    self.repository.updateEntries(entries)
                    self.delegate?.didUpdate(controller: self)
                    
                case .failure(let error):
                    self.delegate?.didFailToLoad(controller: self, error: error)
                }
            }
        }
    }

    // retrieve wallets from db
    func wallets(_ searchTerm: String? = nil) -> [WCAppRegistryEntry] {
        repository.entries(searchTerm: searchTerm, role: .wallet)
    }
}
