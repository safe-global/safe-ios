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

    public override func tearDown() {
        super.tearDown()
        // Is it possible to always have a clean/empty keychain?
        try! keychainStorage.deleteItem(.generic(id: KeychainStorage.derivedPasswordTag, service: ProtectionClass.sensitive.service()))
        try! keychainStorage.deleteItem(.generic(id: KeychainStorage.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service()))
        try! keychainStorage.deleteItem(.ecPubKey())
        try! keychainStorage.deleteItem(.enclaveKey())
    }

    func testInitialSetup() {
        XCTAssertEqual(encryptedStore.isInitialized(), false)
        do {
            try encryptedStore.initializeKeyStore()
        } catch {
            XCTFail() // do not throw
        }
        XCTAssertEqual(encryptedStore.isInitialized(), true)
    }

    func testImport() throws {
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as EthPrivateKey
        try encryptedStore.initializeKeyStore()

        try encryptedStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364", protectionClass: .sensitive), ethPrivateKey: randomKey)

        let ethPrivateKey = try encryptedStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364", protectionClass: .sensitive), password: nil)
        XCTAssertEqual(ethPrivateKey, randomKey)
    }

    func testEthereumKeyNotFound() throws {
        try encryptedStore.initializeKeyStore()

        let ethPrivateKey = try encryptedStore.find(dataID: DataID(id: "0xfb1ca734579C3F2dC6DC8cD64A4f5D91891387C6", protectionClass: .sensitive), password: nil)
        XCTAssertEqual(ethPrivateKey, nil)
    }
}
