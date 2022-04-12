//
//  WCAppRegistryMigration.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

extension KeyInfo {
    struct WalletConnectKeyMetadata: Codable {
        let walletInfo: Session.WalletInfo
        let installedWallet: InstalledWallet?

        var data: Data {
            try! JSONEncoder().encode(self)
        }

        static func from(data: Data) -> Self? {
            try? JSONDecoder().decode(Self.self, from: data)
        }
    }
    /// WalletConnect keys store metadata with information if a key was connected with installed wallet on a device.
    /// This parameter is a helper to fetch this data.
    var installedWallet: InstalledWallet? {
        guard let metadata = metadata else { return nil }
        return WalletConnectKeyMetadata.from(data: metadata)?.installedWallet
    }
}

struct InstalledWallet: Codable {
    let name: String
    let imageName: String
    let scheme: String
    let universalLink: String
}

class WCAppRegistryMigration: WCRegistryControllerDelegate {

    static let shared = WCAppRegistryMigration()

    enum State {
        case initial
        case fetching
        case migrating
        case failed
        case done
        case skipped
    }

    private(set) var state = State.initial {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.self.run()
            }
        }
    }

    private(set) var registryController = WCRegistryController()

    init() {
        registryController.delegate = self
    }

    func run() {
        switch state {
        case .initial:
            LogService.shared.debug("WCAppRegistryMigration: checking if migration needed.")
            if AppSettings.walletAppRegistryMigrationCompleted {
                state = .skipped
            } else {
                state = .fetching
            }

        case .fetching:
            LogService.shared.debug("WCAppRegistryMigration: fetching registry data.")
            registryController.loadData()

        case .migrating:
            LogService.shared.debug("WCAppRegistryMigration: updating database.")
            migrate()

        case .failed:
            LogService.shared.debug("WCAppRegistryMigration: failed.")

        case .done:
            AppSettings.walletAppRegistryMigrationCompleted = true
            LogService.shared.debug("WCAppRegistryMigration: completed successfully.")

        case .skipped:
            LogService.shared.debug("WCAppRegistryMigration: migrated already.")
        }
    }

    func didUpdate(controller: WCRegistryController) {
        state = .migrating
    }

    func didFailToLoad(controller: WCRegistryController, error: Error) {
        LogService.shared.error("WCAppRegistryMigration: failed to migrate to the new wallet registry: \(error)")
        state = .failed
    }

    func migrate() {
        // get all wallets with installed wallet
        do {
            let keys = try KeyInfo.keys(types: [.walletConnect])

            for key in keys {
                guard let installedWallet = key.installedWallet else {
                    continue
                }

                // find a registry entry with the same name

                if let registryEntry = registryController.repository.entries(searchTerm: installedWallet.name, role: .wallet).first,
                   let cdRegistryEntry = CDWCAppRegistryEntry.entry(by: registryEntry.id) {
                    key.wallet = cdRegistryEntry
                }

                // delete the installed wallet metadata
                key.metadata = nil
            }

            App.shared.coreDataStack.saveContext()

            state = .done
        } catch {
            LogService.shared.debug("WCAppRegistryMigration: failed to migrate key infos: \(error)")
            state = .failed
        }
    }
}
