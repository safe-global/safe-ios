//
//  CryptoCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class CryptoCenter {

    typealias EthPrivateKey = String

    func `import`(privateKey: EthPrivateKey) {
        // store encrypted key for the address
            // find public senstive key
            // encrypt private key with public sensitive key
            // store encrypted blob in the keychain
    }

    func delete(address: Address) {
        // delete encrypted blob by address
    }

    func sign(data: Data, address: Address, password: String) -> Signature {
        // find encrypted private key for the address
        // decrypt encrypted private key
            // find encrypted sensitive key
            // decrypt encrypted sensitive key
                // find key encryption key
                // set password credentials
                // decrypt sensitive key
            // decrypt the private key with sensitive key
        // sign data with private key
        // return signature
        preconditionFailure()
    }

    func verify() {}

    func changePassword(from oldPassword: String, to newPassword: String) {
        // create a new kek
        // decrypt private senstivie key with kek
        // encrypt sensitive key with new kek

        // decrypt data key with old data kek
        // encrypt data key with new data kek
    }

    func changeSettings() {
        // Settings

        //  change password
        //  enable / disable password

        //  use biometry
        //  use password in addition to face id when signing

    }

}

