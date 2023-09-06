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

    static func generate() -> PrivateKey {
        // 16 bit = 12 words
        let seed = Data.randomBytes(length: 16)!
        let mnemonic = BIP39.generateMnemonicsFromEntropy(entropy: seed)!
        let key = try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
        return key
    }

    static func importKey(_ privateKey: PrivateKey,
                          name: String,
                          type: KeyType,
                          isDerivedFromSeedPhrase: Bool) -> Bool {
        do {
            guard KeyType.privateKeyTypes.contains(type) else {
                App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key."))
                return false
            }

            try KeyInfo.import(address: privateKey.address, name: name, privateKey: privateKey, type: type)

            App.shared.notificationHandler.signingKeyUpdated()

            switch type {
            case .deviceImported:
                Tracker.setNumKeys(KeyInfo.count(.deviceImported), type: .deviceImported)
                Tracker.trackEvent(.ownerKeyImported,
                                   parameters: ["import_type": isDerivedFromSeedPhrase ? "seed" : "key"])
            case .deviceGenerated:
                Tracker.setNumKeys(KeyInfo.count(.deviceGenerated), type: .deviceGenerated)
                Tracker.trackEvent(.ownerKeyGenerated)
            case .web3AuthApple:
                Tracker.setNumKeys(KeyInfo.count(.web3AuthApple), type: .web3AuthApple)
                Tracker.trackEvent(.web3AuthKeyApple)
            case .web3AuthGoogle:
                Tracker.setNumKeys(KeyInfo.count(.web3AuthGoogle), type: .web3AuthGoogle)
                Tracker.trackEvent(.web3AuthKeyGoogle)
            default:
                break
            }

            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
            return false
        }
    }

    @discardableResult
    static func importKey(_ key: PrivateKey,
                          name: String,
                          email: String,
                          type: KeyType) -> Bool {
        do {
            guard KeyType.socialKeyTypes.contains(type) else {
                App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key."))
                return false
            }

            try KeyInfo.import(address: key.address, name: name, privateKey: key, type: type, email: email)

            App.shared.notificationHandler.signingKeyUpdated()

            switch type {
            case .web3AuthApple:
                Tracker.setNumKeys(KeyInfo.count(.web3AuthApple), type: .web3AuthApple)
                Tracker.trackEvent(.web3AuthKeyApple)
            case .web3AuthGoogle:
                Tracker.setNumKeys(KeyInfo.count(.web3AuthGoogle), type: .web3AuthGoogle)
                Tracker.trackEvent(.web3AuthKeyGoogle)
            default:
                break
            }

            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
            return false
        }
    }

    @discardableResult
    static func importKey(connection: WebConnection, wallet: WCAppRegistryEntry?, name: String) -> Bool {
        do {
            let newKey = try KeyInfo.import(connection: connection, wallet: wallet, name: name)

            guard newKey != nil else { return false }

            Tracker.setNumKeys(KeyInfo.count(.walletConnect), type: .walletConnect)
            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)

            let name = wallet?.name ?? connection.remotePeer?.name ?? "unknown"
            Tracker.trackEvent(.connectInstalledWallet, parameters: ["wallet": name])

            return true
        } catch {
            if let err = error as? GSError.DuplicateKey {
                App.shared.snackbar.show(error: err)
            } else {
                let err = GSError.error(description: "Failed to add WalletConnect owner", error: error)
                App.shared.snackbar.show(error: err)
            }
            return false
        }
    }

    static func updateKey(_ keyInfo: KeyInfo, connection: WebConnection, wallet: WCAppRegistryEntry?) -> Bool {
        do {
            let updatedKey = try KeyInfo.update(keyInfo: keyInfo, connection: connection)

            guard updatedKey != nil else { return false }

            Tracker.setNumKeys(KeyInfo.count(.walletConnect), type: .walletConnect)
            NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)

            let name = wallet?.name ?? connection.remotePeer?.name ?? "unknown"
            Tracker.trackEvent(.connectInstalledWallet, parameters: ["wallet": name])

            return true
        } catch {
            if let err = error as? DetailedLocalizedError {
                App.shared.snackbar.show(error: err)
            } else {
                let err = GSError.error(description: "Failed to add WalletConnect owner", error: error)
                App.shared.snackbar.show(error: err)
            }
            return false
        }
    }

    /// Import Ledger Nano X key
    @discardableResult
    static func importKey(ledgerDeviceUUID: UUID, path: String, address: Address, name: String) -> Bool {
        do {
            try KeyInfo.import(ledgerDeviceUUID: ledgerDeviceUUID, path: path, address: address, name: name)
            Tracker.setNumKeys(KeyInfo.count(.ledgerNanoX), type: .ledgerNanoX)
            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            Tracker.trackEvent(.ledgerKeyImported)
            return true
        } catch {
            if let err = error as? GSError.DuplicateKey {
                App.shared.snackbar.show(error: err)
            } else {
                let err = GSError.error(description: "Failed to add Ledger owner", error: error)
                App.shared.snackbar.show(error: err)
            }
            return false
        }
    }

    static func importKey(keystone address: Address, path: String, name: String, sourceFingerprint: UInt32) -> Bool {
        do {
            try KeyInfo.import(keystone: address, path: path, name: name, sourceFingerprint: sourceFingerprint)

            App.shared.notificationHandler.signingKeyUpdated()

            Tracker.setNumKeys(KeyInfo.count(.keystone), type: .keystone)
            Tracker.trackEvent(.keystoneKeyImported)

            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Failed to add Keystone owner", error: error))
            return false
        }
    }
    
    static func remove(keyInfo: KeyInfo) {
        // this should be done before calling keyInfo.delete()
        WebConnectionController.shared.userDidDelete(account: keyInfo.address)
        keyInfo.delete(completion: { result in
            do {
                let result = try result.get()
                if result {
                    App.shared.notificationHandler.signingKeyUpdated()
                    App.shared.snackbar.show(message: "Owner key removed from this app")
                    Tracker.trackEvent(.ownerKeyRemoved)
                    Tracker.setNumKeys(KeyInfo.count(keyInfo.keyType), type: keyInfo.keyType)
                    NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
                } else {
                    App.shared.snackbar.show(error: GSError.error(description: "Failed to remove imported key"))
                }
            } catch {
                App.shared.snackbar.show(error: GSError.error(description: "Failed to remove imported key",
                                                              error: error))
            }
        })
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
                privateKey: updatedKey, type: .deviceImported)

            legacyKey.remove()
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

            // delete all device key infos with private keys that are missing
            let keyInfoToDelete = try KeyInfo.keys(types: KeyType.privateKeyTypes).filter { info in
                let shouldDelete: Bool
                do {
                    let keyOrNil = try info.privateKey()
                    shouldDelete = keyOrNil == nil
                } catch {
                    // if error, then the key might still be there
                    // but maybe data access failed for some reason (access while app is in background)
                    // therefore we won't accidentally delete existing key
                    shouldDelete = false
                }
                return shouldDelete
            }

            for info in keyInfoToDelete {
                info.delete()
            }
        } catch {
            LogService.shared.error("Failed to delete all keys: \(error)")
        }
    }

    /// Call this when you want to wipe out all of the keys by the user's request
    static func deleteAllKeys(showingMessage: Bool = true) throws {
        try KeyInfo.deleteAll(authenticate: false)
        App.shared.notificationHandler.signingKeyUpdated()
        if showingMessage {
            App.shared.snackbar.show(message: "All owner keys removed from this app")
        }
        Tracker.trackEvent(.ownerKeyRemoved)
        Tracker.setNumKeys(KeyInfo.count(.deviceGenerated), type: .deviceGenerated)
        Tracker.setNumKeys(KeyInfo.count(.deviceImported), type: .deviceImported)
        Tracker.setNumKeys(KeyInfo.count(.walletConnect), type: .walletConnect)
        Tracker.setNumKeys(KeyInfo.count(.ledgerNanoX), type: .ledgerNanoX)
        Tracker.setNumKeys(KeyInfo.count(.keystone), type: .keystone)
        Tracker.setNumKeys(KeyInfo.count(.web3AuthApple), type: .web3AuthApple)
        Tracker.setNumKeys(KeyInfo.count(.web3AuthGoogle), type: .web3AuthGoogle)
        NotificationCenter.default.post(name: .ownerKeyRemoved, object: nil)
    }
}
