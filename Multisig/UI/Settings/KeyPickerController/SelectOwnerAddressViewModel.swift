//
//  SelectOwnerAddressViewModel.swift
//  Multisig
//
//  Created by Moaaz on 10/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

class SelectOwnerAddressViewModel {
    var addresses = [Address]()
    var selectedIndex = 0

    var rootNode: HDNode? {
        didSet {
            generateAddressesPage()
        }
    }
    var maxAddressesCount = 100
    var pageSize = 20

    var canLoadMoreAddresses: Bool {
        addresses.count < maxAddressesCount
    }

    init(rootNode: HDNode?, onSubmit: (() -> Void)? = nil ) {
        self.rootNode = rootNode
        #if DEBUG
        #warning("Remove when the mobile signing v2 is ready")
        if rootNode == nil {
            self.rootNode = randomNode()
        }
        #endif
        generateAddressesPage()
    }

    #if DEBUG
    private func randomNode() -> HDNode {
        let mnem = try! BIP39.generateMnemonics(bitsOfEntropy: 128)!
        let root = BIP39.seedFromMmemonics(mnem)!
        let node = HDNode(seed: root)!
        let result = node.derive(path: HDNode.defaultPathMetamaskPrefix, derivePrivateKey: true)!
        return result
    }
    #endif

    private func addressAt(_ index: Int) -> Address? {
        guard let pkData = privateKeyData(index) else {
            return nil
        }

        do {
            let address = try EthereumPrivateKey(hexPrivateKey: pkData.toHexString()).address
            return Address(address, index: index)
        } catch {
            App.shared.snackbar.show(
                error: GSError.UnknownAppError(description: "Could not derive address",
                                               reason: "Unexpected error appeared.",
                                               howToFix: "Please reach out to the Safe support"))
            return nil
        }
    }

    private func privateKeyData(_ index: Int) -> Data? {
        rootNode?.derive(index: UInt32(index), derivePrivateKey: true)?.privateKey
    }
    
    func generateAddressesPage() {
        addresses += (0..<pageSize).compactMap { addressAt($0 + addresses.count) }
    }

    func importWallet() -> Bool {
        guard let pkData = privateKeyData(selectedIndex) else { return false }
        do {
            try App.shared.keychainService.removeData(forKey: KeychainKey.ownerPrivateKey.rawValue)
            try App.shared.keychainService.save(data: pkData, forKey: KeychainKey.ownerPrivateKey.rawValue)

            App.shared.settings.updateSigningKeyAddress()
            App.shared.notificationHandler.signingKeyUpdated()

            Tracker.shared.setNumKeysImported(1)
            Tracker.shared.trackEvent(.ownerKeyImported, parameters: ["import_type": "seed"])

            App.shared.snackbar.show(message: "Owner key successfully imported")
            NotificationCenter.default.post(name: .ownerKeyImported, object: nil)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
        }

        return false
    }
}
