//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import LocalAuthentication

public class SensitiveStoreTests: XCTestCase {

    var encryptedStore: EncryptedStore! = nil
    var keychainItemStore: KeychainItemStore! = nil

    public override func setUp() {
        super.setUp()
        keychainItemStore = KeychainItemStore(KeychainStore())
        encryptedStore = SensitiveStore(keychainItemStore)
    }

    public override func tearDown() {
        super.tearDown()
        try! keychainItemStore.delete(.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service()))
        try! keychainItemStore.delete(.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service()))
        try! keychainItemStore.delete(.ecPubKey())
        try! keychainItemStore.delete(.enclaveKey())
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

    func testChangePassword() {
        XCTAssertEqual(encryptedStore.isInitialized(), false)
        do {
            try encryptedStore.initializeKeyStore()

            try encryptedStore.changePassword(from: nil, to: "test123")
            try encryptedStore.changePassword(from: "test123", to: "random")
            try encryptedStore.changePassword(from: "random", to: nil)

        } catch {
            XCTFail() // should not throw
        }
    }

    func testChangePasswordGivenWrongPasswordShouldFail() throws {
        guard simulatorCheck() else {
            throw XCTSkip("Test not supported on simulator")
        }
        XCTAssertEqual(encryptedStore.isInitialized(), false)
        do {
            try encryptedStore.initializeKeyStore()
            try encryptedStore.changePassword(from: nil, to: "test123")
        } catch {
            XCTFail() // should not throw
        }

        do {
            try encryptedStore.changePassword(from: "wrong", to: "random")
            XCTFail() // should've thrown
        } catch {
            // check for correct exception?
        }
    }

    private func simulatorCheck() -> Bool {
        LAContext().setCredential("anyPassword".data(using: .utf8), type: .applicationPassword)
    }
}
