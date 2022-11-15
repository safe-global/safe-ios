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
        // Given
        keychainStorage = KeychainStorage()
        encryptedStore = SensitiveEncryptedStore(keychainStorage)
    }

    func testInitialSetup() {
        print("testing initialSetup()")
        do {
            // When
            try encryptedStore.initialSetup()
            encryptedStore.import(privateKey: "0xF000")

            // then
            // Check kc


        } catch {
            // log errors
            LogService.shared.error("initialSetup: \(error)")
            XCTFail()
        }

    }
}
