//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import LocalAuthentication

public class SensitiveStoreTests: XCTestCase {

    var sensitiveKeyStore: EncryptedStore! = nil
    var dataKeyStore: EncryptedStore! = nil
    var keychainItemStore: KeychainItemStore! = nil

    public override func setUp() {
        super.setUp()
        keychainItemStore = KeychainItemStore(KeychainStore())
        sensitiveKeyStore = SensitiveStore(protectionClass: .sensitive, keychainItemStore)
        dataKeyStore = SensitiveStore(protectionClass: .data, keychainItemStore)
    }

    public override func tearDown() {
        super.tearDown()
        try! sensitiveKeyStore.deleteAllKeys()
    }

    func testInitialSetup() {
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), false)
        do {
            try sensitiveKeyStore.initializeKeyStore()
        } catch {
            XCTFail() // do not throw
        }
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), true)
    }

    func testImport() throws {
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as EthPrivateKey
        try sensitiveKeyStore.initializeKeyStore()

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), ethPrivateKey: randomKey)

        let result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
    }

    func testEthereumKeyNotFound() throws {
        try sensitiveKeyStore.initializeKeyStore()

        let ethPrivateKey = try sensitiveKeyStore.find(dataID: DataID(id: "0xfb1ca734579C3F2dC6DC8cD64A4f5D91891387C6"), password: nil)
        XCTAssertEqual(ethPrivateKey, nil)
    }

    func testChangePassword() {
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), false)
        do {
            try sensitiveKeyStore.initializeKeyStore()

            try sensitiveKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "test123", to: "random", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "random", to: nil, useBiometry: false)

        } catch {
            XCTFail() // should not throw
        }
    }

    func testChangePasswordGivenWrongPasswordShouldFail() throws {
        guard simulatorCheck() else {
            throw XCTSkip("Test not supported on simulator")
        }
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), false)
        do {
            try sensitiveKeyStore.initializeKeyStore()
            try sensitiveKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)
        } catch {
            XCTFail() // should not throw
        }

        do {
            try sensitiveKeyStore.changePassword(from: "wrong", to: "random", useBiometry: false)
            XCTFail() // should've thrown
        } catch {
            // check for correct exception?
        }
    }

    func testBiometryOnly() throws {
        guard simulatorCheck() else {
            throw XCTSkip("Test not supported on simulator")
        }
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), false)
        do {
            try sensitiveKeyStore.initializeKeyStore()

            try sensitiveKeyStore.changePassword(from: nil, to: nil, useBiometry: true)

            // check ?
            try sensitiveKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "test123", to: "random", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "random", to: nil, useBiometry: false)

        } catch {
            XCTFail() // should not throw
        }
    }

    func testImportDataKey() throws {
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as EthPrivateKey
        try dataKeyStore.initializeKeyStore()

        try dataKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), ethPrivateKey: randomKey)

        let result = try dataKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
    }

    func testImportDataAndSensitiveKeyStore() throws {
        let randomSensitiveKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as EthPrivateKey
        try sensitiveKeyStore.initializeKeyStore()

        let randomDataKey = Data(ethHex: "cb18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c321") as EthPrivateKey
        try dataKeyStore.initializeKeyStore()

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), ethPrivateKey: randomSensitiveKey)
        try dataKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), ethPrivateKey: randomDataKey)

        let result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomSensitiveKey.toHexString())

        let result2 = try dataKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result2?.toHexString(), randomDataKey.toHexString())

    }

    private func simulatorCheck() -> Bool {
        LAContext().setCredential("anyPassword".data(using: .utf8), type: .applicationPassword)
    }
}
