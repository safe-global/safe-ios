//
//  PrivateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class PrivateKeyController {
    static func importKey(_ privateKey: PrivateKey, name: String, isDrivedFromSeedPhrase: Bool) -> Bool {
        do {
            try KeyInfo.import(address: privateKey.address, name: name, privateKey: privateKey)

            App.shared.notificationHandler.signingKeyUpdated()

            Tracker.shared.setNumKeysImported(1)
            Tracker.shared.track(event: TrackingEvent.ownerKeyImported, parameters: ["import_type": isDrivedFromSeedPhrase ? "seed" : "key"])

            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
            return false
        }
    }

    static func removeKey() {
        do {
            try PrivateKey.remove(id: PrivateKey.v1KeyID)
            App.shared.notificationHandler.signingKeyUpdated()
            App.shared.snackbar.show(message: "Owner key removed from this app")
            Tracker.shared.setNumKeysImported(0)
            NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Failed to remove imported key", error: error))
        }
    }

    static var signingKeyAddress: String? {
        try? PrivateKey.v1SingleKey()?.address.checksummed
    }

    static var hasPrivateKey: Bool {
        KeyInfo.count > 0
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

            let updatedKey = try PrivateKey(data: legacyKey.data)
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
}
