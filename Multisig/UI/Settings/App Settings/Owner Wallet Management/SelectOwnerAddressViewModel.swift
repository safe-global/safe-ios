//
//  SelectOwnerAddressViewModel.swift
//  Multisig
//
//  Created by Moaaz on 10/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import Web3

class SelectOwnerAddressViewModel: ObservableObject {
    @Published
    var addresses = [Address]()
    @Published
    var selectedIndex = 0

    private var rootNode: HDNode?
    private var maxAddressesCount = 100
    private var pageSize = 20

    var canLoadMoreAddresses: Bool {
        addresses.count < maxAddressesCount
    }

    init(rootNode: HDNode?, onSubmit: (() -> Void)? = nil ) {
        self.rootNode = rootNode
        generateAddressesPage()
    }

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
            App.shared.snackbar.show(message: "Owner key successfully imported")
            Tracker.shared.setNumKeysImported(1)
            return true
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not import signing key.", error: error))
        }

        return false
    }
}
