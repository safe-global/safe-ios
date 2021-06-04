//
//  OwnerKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class OwnerKeyController {
    static func importKey(_ privateKey: PrivateKey, name: String, isDrivedFromSeedPhrase: Bool) -> Bool {
        do {
            try KeyInfo.import(address: privateKey.address, name: name, privateKey: privateKey)

            App.shared.notificationHandler.signingKeyUpdated()

            if privateKey.mnemonic != nil { // generating key on mobile
                Tracker.shared.setNumKeys(KeyInfo.count(.deviceGenerated), type: .deviceGenerated)
                Tracker.shared.track(event: TrackingEvent.ownerKeyGenerated)
            } else { // importing key
                Tracker.shared.setNumKeys(KeyInfo.count(.deviceImported), type: .deviceImported)
                Tracker.shared.track(event: TrackingEvent.ownerKeyImported,
                                     parameters: ["import_type": isDrivedFromSeedPhrase ? "seed" : "key"])
            }

            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
            return false
        }
    }

    static func importKey(session: Session, installedWallet: InstalledWallet?) -> Bool {
        do {
            try KeyInfo.import(session: session, installedWallet: installedWallet)
            Tracker.shared.setNumKeys(KeyInfo.count(.walletConnect), type: .walletConnect)
            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)

            if installedWallet != nil {
                Tracker.shared.track(event: TrackingEvent.connectInstalledWallet)
            } else {
                Tracker.shared.track(event: TrackingEvent.connectExternalWallet)
            }

            return true
        } catch {
            if let err = error as? GSError.CouldNotImportOwnerKeyWithSameAddressAndDifferentType {
                App.shared.snackbar.show(error: err)
            } else {
                let err = GSError.error(description: "Failed to add WalletConnect owner", error: error)
                App.shared.snackbar.show(error: err)
            }
            return false
        }
    }

    // we need to update to always properly refresh session.walletInfo.peerId
    // that we use to identify if the wallet is connected
    static func updateKey(session: Session, installedWallet: InstalledWallet?) -> Bool {
        do {
            try KeyInfo.import(session: session, installedWallet: installedWallet)
            return true
        } catch {
            let err = GSError.error(description: "Failed to update WalletConnect owner key", error: error)
            App.shared.snackbar.show(error: err)
            return false
        }
    }

    static func remove(keyInfo: KeyInfo) {
        do {
            // this should be done before calling keyInfo.delete()
            if keyInfo.keyType == .walletConnect {
                WalletConnectClientController.shared.disconnect()
            }
            try keyInfo.delete()
            App.shared.notificationHandler.signingKeyUpdated()
            App.shared.snackbar.show(message: "Owner key removed from this app")
            Tracker.shared.track(event: TrackingEvent.ownerKeyRemoved)
            Tracker.shared.setNumKeys(KeyInfo.count(keyInfo.keyType), type: keyInfo.keyType)
            NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Failed to remove imported key", error: error))
        }
    }

    static func edit(keyInfo: KeyInfo, name: String) {
        keyInfo.rename(newName: name)
        App.shared.snackbar.show(message: "Owner key updated")
        NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)
    }

    static var hasPrivateKey: Bool {
        KeyInfo.count() > 0
    }

    static func exists(_ privateKey: PrivateKey) -> Bool {
        do {
            return try !KeyInfo.privateKeys(addresses: [privateKey.address]).isEmpty
        } catch {
            return false
        }
    }

    // If user already imported a key in a previous app version, then
    // the key’s name will be “Key 0x1234...2345” where the “0x…” part is
    // the ellipsized address of the key
    static func migrateLegacySigningKey() {
        do {
            // Table below describes different possible
            // combinations of the information and what to do for
            // legacy key, existing key info and existing private key
            //
            // 1 ~ "is not nil"
            // 0 ~ "is nil"
            //
            // legacy  exInfo  exKey
            // 1        0       0     not migrated, create key info and new key
            // 1        0       1     migration failed, create key info and use existing key
            // 1        1       0     migration failed, create new key and update key info
            // 1        1       1     migrated already, override existing
            // 0        *       *     migration not possible, exit

            guard let legacyKey = try PrivateKey.v1SingleKey() else {
                // migration not possible, exit
                return
            }

            let updatedKey = try PrivateKey(data: legacyKey.keyData)
            let existingKeyInfoOrNil = try KeyInfo.keys(addresses: [legacyKey.address]).first

            // wipe out any existing keys associated with the info.
            if let keyInfo = existingKeyInfoOrNil, keyInfo.keyID != updatedKey.id {
                try keyInfo.privateKey()?.remove()
            }

            let defaultName = "Key \(updatedKey.address.ellipsized())"

            // import new or override existing key info and private key
            try KeyInfo.import(
                address: legacyKey.address,
                name: existingKeyInfoOrNil?.name ?? defaultName,
                privateKey: updatedKey)

            try legacyKey.remove()
        } catch {
            // silence any warnings because this should run in a stealth mode
            LogService.shared.error("Failed to migrate legacy key: \(error)")
        }
    }

    /// Removes private keys on fresh install. Also, will remove all key infos
    /// which don't have any private key stored (stale data).
    ///
    /// This is needed because the Keychain doesn't get cleared when
    /// an app is removed from the phone. On the next installation
    /// all of the Keychain data will be present.
    ///
    /// The case when there are KeyInfo data (CoreData) are present but
    /// the Keychain data doesn't exist happens when users restore phones
    /// from the iCloud backup, which restores the application data but
    /// does not restore Keychain. It would not happen if a user would
    /// restore from encrypted backup, which restores Keychain data as well.
    static func cleanUpKeys() {
        do {
            if AppSettings.isFreshInstall {
                try PrivateKey.deleteAll()
            }

            // delete all device key infos whos private keys do not exist
            let infos = try KeyInfo.keys(types: [.deviceImported, .deviceGenerated]).filter {
                !$0.hasPrivateKey
            }
            try infos.forEach { try $0.delete() }
        } catch {
            LogService.shared.error("Failed to delete all keys: \(error)")
        }
    }

    /// Call this when you want to wipe out all of the keys by the user's request
    static func deleteAllKeys(showingMessage: Bool = true) throws {
        try KeyInfo.deleteAll()
        App.shared.notificationHandler.signingKeyUpdated()
        if showingMessage {
            App.shared.snackbar.show(message: "All owner keys removed from this app")
        }
        Tracker.shared.track(event: TrackingEvent.ownerKeyRemoved)
        Tracker.shared.setNumKeys(KeyInfo.count(.deviceGenerated), type: .deviceGenerated)
        Tracker.shared.setNumKeys(KeyInfo.count(.deviceImported), type: .deviceImported)
        Tracker.shared.setNumKeys(KeyInfo.count(.walletConnect), type: .deviceImported)
        NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
    }
}
