//
//  PrivateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class PrivateKeyController {
    static func importKey(_ privateKey: Data) -> Bool {
        do {
            try App.shared.keychainService.removeData(forKey: KeychainKey.ownerPrivateKey.rawValue)
            try App.shared.keychainService.save(data: privateKey, forKey: KeychainKey.ownerPrivateKey.rawValue)

            App.shared.settings.updateSigningKeyAddress()
            App.shared.notificationHandler.signingKeyUpdated()

            Tracker.shared.setNumKeysImported(1)
            Tracker.shared.track(event: TrackingEvent.ownerKeyImported, parameters: ["import_type": "seed"])

            App.shared.snackbar.show(message: "Owner key successfully imported")
            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
            return false
        }
    }
}
