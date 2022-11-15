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
    }

    public override func tearDown() {
        super.tearDown()
        // Is it possible to always have a clean/empty keychain?
        keychainCenter.deleteData(KeychainCenter.derivedPasswordTag)
        keychainCenter.deleteData(KeychainCenter.sensitiveEncryptedPrivateKeyTag)
    }

    func testStoreAndRetrievePasscode() {
        // Given
        XCTAssertEqual(keychainCenter.retrievePasscode(), nil, "Keychain not empty")

        // When
        keychainCenter.storePasscode(derivedPasscode: "foo")

        //Then
        let result = keychainCenter.retrievePasscode()
        XCTAssertEqual(result, "foo", "Unexpected result: \(result)")
    }

    func testStoreAndRetrieveSensitivePrivateKey() throws {

        // Given
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Keychain not empty!")

        // When
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: "foo".data(using: .utf8)!)

        //Then
        let result = try keychainCenter.retrieveEncryptedSensitivePrivateKeyData()
        XCTAssertEqual(result, "foo".data(using: .utf8)!)
    }

    func testDeleteData() throws {
        // Given
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Keychain not empty!")
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: "foo".data(using: .utf8)!)

        // When
        keychainCenter.deleteData(KeychainCenter.sensitiveEncryptedPrivateKeyTag)

        //Then
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Deletion failed")
    }

}
