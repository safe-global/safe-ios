//
//  MockSecureStore.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
@testable import Multisig

class MockSecureStore: SecureStore {

    private var _store = [String: Data]()

    func save(data: Data, forKey: String) throws {
        _store[forKey] = data
    }

    func data(forKey: String) throws -> Data? {
        return _store[forKey]
    }

    func allKeys() throws -> [String] {
        Array(_store.keys)
    }

    func removeData(forKey: String) throws {
        _store.removeValue(forKey: forKey)
    }

    func destroy() throws {
        _store = [String: Data]()
    }
}
