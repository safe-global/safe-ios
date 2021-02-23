//
//  PrivateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class PrivateKeyController {
    static func importKey(_ privateKey: Data, isDrivedFromSeedPhrase: Bool) -> Bool {
        do {
            try App.shared.keychainService.removeData(forKey: KeychainKey.ownerPrivateKey.rawValue)
            try App.shared.keychainService.save(data: privateKey, forKey: KeychainKey.ownerPrivateKey.rawValue)

            App.shared.settings.updateSigningKeyAddress()
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
            try App.shared.keychainService.removeData(
                forKey: KeychainKey.ownerPrivateKey.rawValue)
            App.shared.settings.updateSigningKeyAddress()
            App.shared.notificationHandler.signingKeyUpdated()
            App.shared.snackbar.show(message: "Owner key removed from this app")
            Tracker.shared.setNumKeysImported(0)
            NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Failed to remove imported key", error: error))
        }
    }
}
