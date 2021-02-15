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

    init(rootNode: HDNode, onSubmit: (() -> Void)? = nil ) {
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
        return PrivateKeyController.importKey(pkData, isDrivedFromSeedPhrase: true)
    }
}
