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
        guard let pkData = rootNode?.derive(index: UInt32(index), derivePrivateKey: true)?.privateKey else {
            return nil
        }

        do {
            let address = try EthereumPrivateKey(hexPrivateKey: pkData.toHexString()).address
            return Address(address, index: index)
        } catch {
            return nil
        }
    }
    
    func generateAddressesPage() {
        addresses += (1...pageSize).compactMap { addressAt($0 + addresses.count) }
    }

    func importWallet() -> Bool {
        guard let pkData = rootNode?.derive(index: UInt32(selectedIndex),
                                            derivePrivateKey: true)?.privateKey else { return false }
        do {
            try App.shared.keychainService.removeData(forKey: KeychainKey.ownerPrivateKey.rawValue)
            try App.shared.keychainService.save(data: pkData, forKey: KeychainKey.ownerPrivateKey.rawValue)
            AppSettings.setSigningKeyAddress(addresses[selectedIndex].checksummed)
            App.shared.snackbar.show(message: "Owner key successfully imported")
            return true
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }

        return false
    }
}
