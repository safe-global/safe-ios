//
// Created by Dirk Jäckel on 09.01.23.
// Copyright (c) 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class DataKeyStoreTest: XCTestCase {

    var encryptedStore: EncryptedStore! = nil
    var keychainItemStore: KeychainItemStore! = nil

    public override func setUp() {
        super.setUp()
        keychainItemStore = KeychainItemStore(KeychainStore())
        encryptedStore = DataKeyStore(keychainItemStore)
    }

    public override func tearDown() {
        super.tearDown()
        try! keychainItemStore.delete(.generic(id: DataKeyStore.storedPasswordTag, service: ProtectionClass.data.service()))
        try! keychainItemStore.delete(.generic(id: DataKeyStore.dataEncryptedPrivateKeyTag, service: ProtectionClass.data.service()))
        try! keychainItemStore.delete(.ecPubKey(tag: DataKeyStore.dataPublicKeyTag))
        try! keychainItemStore.delete(.enclaveKey(tag: DataKeyStore.dataPrivateKEKTag))
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

        let result = try encryptedStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364", protectionClass: .sensitive), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
    }

    func testEthereumKeyNotFound() throws {
        try encryptedStore.initializeKeyStore()

        let ethPrivateKey = try encryptedStore.find(dataID: DataID(id: "0xfb1ca734579C3F2dC6DC8cD64A4f5D91891387C6", protectionClass: .sensitive), password: nil)
        XCTAssertEqual(ethPrivateKey, nil)
    }
}
