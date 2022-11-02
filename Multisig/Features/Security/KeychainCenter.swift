//
//  KeychainCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class KeychainCenter {

    // used to create KEK
    func createSecureEnclaveKey() {}

    // used to create a public-private key pair (asymmetric)
    func createKeyPair() {}

    // used to find a KEK or a private key
    func findPrivateKey() {}

    func findPublicKey() {}


    func deleteItem(tag: String) {}

    func saveItem(data: Data, tag: String) {}

    func findItem(tag: String) -> Data? {
        preconditionFailure()
    }

    func encrypt() {

    }

    func decrypt() {
    }
}
