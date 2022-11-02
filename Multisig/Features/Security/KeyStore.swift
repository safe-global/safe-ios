//
//  KeyStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SecureItemID {

}

class SecureItem {
    let id: SecureItemID

    internal init(id: SecureItemID) {
        self.id = id
    }
}

class KeyStore {

    func save(_ key: SecureItem) {
        // SecItemAdd
    }

    func find(_ id: SecureItemID) -> SecureItem? {
        preconditionFailure()
    }

    func delete(_ id: SecureItemID) {
        preconditionFailure()
    }

    func update(_ key: Key) -> SecureItem {
        preconditionFailure()
    }

}

