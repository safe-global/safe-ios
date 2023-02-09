//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import LocalAuthentication

public class ProtectedKeyStoreTests: XCTestCase {

    var sensitiveKeyStore: ProtectedKeyStore! = nil
    var dataKeyStore: ProtectedKeyStore! = nil
    var keychainItemStore: KeychainItemStore! = nil

    public override func setUp() {
        super.setUp()
        keychainItemStore = KeychainItemStore(KeychainStore())
        sensitiveKeyStore = ProtectedKeyStore(protectionClass: .sensitive, keychainItemStore)
        dataKeyStore = ProtectedKeyStore(protectionClass: .data, keychainItemStore)
    }

    public override func tearDown() {
        super.tearDown()
        do {
            try sensitiveKeyStore.deleteAllKeys()
        } catch {}
        do {
            try! dataKeyStore.deleteAllKeys()
        } catch {}
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
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as Data
        try sensitiveKeyStore.initializeKeyStore()

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomKey)

        let result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
    }

    func testImportOverride() throws {
        let randomKey1 = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as Data
        let randomKey2 = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c323") as Data
        try sensitiveKeyStore.initializeKeyStore()

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomKey1)
        var result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey1.toHexString())

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomKey2)
        result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey2.toHexString())
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

    func testAfterChangePasswordKeysAreStillAvailable() {
        XCTAssertEqual(dataKeyStore.isInitialized(), false)
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as Data
        do {
            try dataKeyStore.initializeKeyStore()
            // Store something
            try dataKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomKey)

            // Change password
            try dataKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)

        } catch {
            XCTFail()
        }
        do {
            // Check imported key can be decrypted
            let result = try dataKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: "test123")
            XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
        } catch {
            XCTFail("Imported data could not be found/decrypted")
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
        let randomKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as Data
        try dataKeyStore.initializeKeyStore()

        try dataKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomKey)

        let result = try dataKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomKey.toHexString())
    }

    func testImportDataAndSensitiveKeyStore() throws {
        let randomSensitiveKey = Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322") as Data
        try sensitiveKeyStore.initializeKeyStore()

        let randomDataKey = Data(ethHex: "cb18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c321") as Data
        try dataKeyStore.initializeKeyStore()

        try sensitiveKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomSensitiveKey)
        try dataKeyStore.import(id: DataID(id:"0xE86935943315293154c7AD63296b4e1adAc76364"), data: randomDataKey)

        let result = try sensitiveKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result?.toHexString(), randomSensitiveKey.toHexString())

        let result2 = try dataKeyStore.find(dataID: DataID(id: "0xE86935943315293154c7AD63296b4e1adAc76364"), password: nil)
        XCTAssertEqual(result2?.toHexString(), randomDataKey.toHexString())

    }

    func testChangePasswordDataAndSensitiveStore() {
        XCTAssertEqual(sensitiveKeyStore.isInitialized(), false)
        do {
            try sensitiveKeyStore.initializeKeyStore()
            try dataKeyStore.initializeKeyStore()

            try sensitiveKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)
            try dataKeyStore.changePassword(from: nil, to: "test123", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "test123", to: "random", useBiometry: false)
            try dataKeyStore.changePassword(from: "test123", to: "random", useBiometry: false)
            try sensitiveKeyStore.changePassword(from: "random", to: nil, useBiometry: false)
            try dataKeyStore.changePassword(from: "random", to: nil, useBiometry: false)

        } catch {
            XCTFail() // should not throw
        }
    }

    private func simulatorCheck() -> Bool {
        LAContext().setCredential("anyPassword".data(using: .utf8), type: .applicationPassword)
    }
}
