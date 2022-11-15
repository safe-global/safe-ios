//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class KeychainCenterTests: XCTestCase {

    var keychainCenter: KeychainCenter! = nil
    let derivedPasscode = "foo"

    public override func setUp() {
        super.setUp()
        // Given
        keychainCenter = KeychainCenter()
        // Is it possible to always have a clean/empty keychain?
        keychainCenter.deleteData(KeychainCenter.derivedPasswordTag)
        keychainCenter.deleteData(KeychainCenter.sensitiveEncryptedPrivateKeyTag)
    }

    func testStorePasscode() {

        // When
        keychainCenter.storePasscode(derivedPasscode: "foo")

        //Then
        let result = keychainCenter.retrievePasscode()
        XCTAssert(result == "foo")

    }

    func testRetrievePasscode() {
        // Given
        XCTAssert(keychainCenter.retrievePasscode() == nil)

        // When
        keychainCenter.storePasscode(derivedPasscode: "foo")

        //Then
        let result = keychainCenter.retrievePasscode()
        XCTAssert(result == "foo")

    }

    func testStoreSensitivePrivateKey() throws {

        // Given
        XCTAssert(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData() == nil)

        // When
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: "foo".data(using: .utf8)!)

        //Then
        let result = try keychainCenter.retrieveEncryptedSensitivePrivateKeyData()
        XCTAssert(result == "foo".data(using: .utf8)!)

    }

    func testFindEncryptedSensitivePrivateKeyData() throws {

        // Given
        XCTAssert(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData() == nil)

        // When
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: "foo".data(using: .utf8)!)

        //Then
        let result = try keychainCenter.retrieveEncryptedSensitivePrivateKeyData()
        XCTAssert(result == "foo".data(using: .utf8)!)
    }

}
