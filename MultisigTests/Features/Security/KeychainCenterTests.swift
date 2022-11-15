//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class KeychainCenterTests: XCTestCase {

    var keychainCenter: KeychainCenter! = nil
    let derivedPasscode = "foobar23"

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
        let randomString = UUID().uuidString
        XCTAssertEqual(keychainCenter.retrievePasscode(), nil, "Keychain not empty")

        // When
        keychainCenter.storePasscode(derivedPasscode: randomString)

        //Then
        let result = keychainCenter.retrievePasscode()
        XCTAssertEqual(result, randomString, "Unexpected result: \(result)")
    }

    func testStoreAndRetrieveSensitivePrivateKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Keychain not empty!")

        // When
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: randomData)

        //Then
        let result = try keychainCenter.retrieveEncryptedSensitivePrivateKeyData()
        XCTAssertEqual(result, randomData)
    }

    func testDeleteData() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Keychain not empty!")
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: randomData)

        // When
        keychainCenter.deleteData(KeychainCenter.sensitiveEncryptedPrivateKeyTag)

        //Then
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Deletion failed")
    }

}
