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
        do {
            try encryptedStore.initializeKeyStore()
        } catch {
            XCTFail() // do not throw
        }
    }

    func testImport() throws {
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as EthPrivateKey
        try encryptedStore.initializeKeyStore()

        try encryptedStore.import(ethPrivateKey: randomKey)

        let ethPrivateKey = try encryptedStore.find(id: "0xE86935943315293154c7AD63296b4e1adAc76364", password: nil)
        XCTAssertEqual(ethPrivateKey, randomKey)
    }

    func testEthereumKeyNotFound() throws {
        try encryptedStore.initializeKeyStore()

        let ethPrivateKey = try encryptedStore.find(id: "0xfb1ca734579C3F2dC6DC8cD64A4f5D91891387C6", password: nil)
        XCTAssertEqual(ethPrivateKey, nil)
    }
}
