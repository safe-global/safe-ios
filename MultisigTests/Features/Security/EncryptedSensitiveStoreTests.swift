//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

public class EncryptedSensitiveStoreTests: XCTestCase {

    var encryptedStore: EncryptedStore! = nil
    var keychainStorage: KeychainStorage! = nil

    public override func setUp() {
        super.setUp()
        keychainStorage = KeychainStorage()
        encryptedStore = SensitiveEncryptedStore(keychainStorage)
    }

    func testInitialSetup() {
        // Given
        do {
            // When
            try encryptedStore.initialSetup()
        } catch {
            // Then
            XCTFail() // do not throw
        }
    }
}
