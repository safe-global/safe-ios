//
//  Settings.swift
//  Multisig
//
//  Created by Moaaz on 10/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3
import Combine

class Settings: NSObject, ObservableObject {
    @Published
    var signingKeyAddress: String?

    override init() {
        super.init()
        updateSigningKeyAddress()
    }

    func updateSigningKeyAddress() {
        guard let pkData = try? App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue),
              let privateKey = try? EthereumPrivateKey(pkData.bytes) else {
            signingKeyAddress = nil
            return
        }
        signingKeyAddress = privateKey.address.hex(eip55: true)
    }
}
