//
//  PrivateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3
class PrivateKeyController {
    static func importKey(_ privateKey: Data, isDrivedFromSeedPhrase: Bool) -> Bool {
        do {
            try PrivateKey(legacy: privateKey).save()

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
            try PrivateKey.remove(id: PrivateKey.legacyKeyID)
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
        try? PrivateKey.legacySingleKey()?.address.checksummed
    }

    static var hasPrivateKey: Bool {
        signingKeyAddress != nil
    }
}
