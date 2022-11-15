//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class KeychainCenterTests: XCTestCase {

    var keychainCenter: KeychainStorage! = nil
    let derivedPasscode = "foobar23"

    public override func setUp() {
        super.setUp()
        // Given
        keychainCenter = KeychainStorage()
    }

    public override func tearDown() {
        super.tearDown()
        // Is it possible to always have a clean/empty keychain?
        keychainCenter.deleteData(KeychainStorage.derivedPasswordTag)
        keychainCenter.deleteData(KeychainStorage.sensitiveEncryptedPrivateKeyTag)
        keychainCenter.deleteItem(tag: KeychainStorage.sensitivePublicKeyTag)
    }

    func testDeleteData() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Precondition failed: Keychain not empty!")
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: randomData)

        // When
        keychainCenter.deleteData(KeychainStorage.sensitiveEncryptedPrivateKeyTag)

        //Then
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Deletion failed")
    }

    func testDeleteItem() throws {
        // Given
        let randomKey = try keychainCenter.createKeyPair()
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertEqual(try keychainCenter.retrieveSensitivePublicKey(), nil, "Precondition failed: Keychain not empty!")
        try keychainCenter.storeSensitivePublicKey(publicKey: randomPublicKey)

        // When
        keychainCenter.deleteItem(tag: KeychainStorage.sensitivePublicKeyTag)

        //Then
        XCTAssertEqual(try keychainCenter.retrieveSensitivePublicKey(), nil, "Delete item failed")
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
        XCTAssertEqual(try keychainCenter.retrieveEncryptedSensitivePrivateKeyData(), nil, "Precondition failed: Keychain not empty!")

        // When
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: randomData)

        //Then
        let result = try keychainCenter.retrieveEncryptedSensitivePrivateKeyData()
        XCTAssertEqual(result, randomData)
    }

    func testStoreAndRetrieveSensitivePublicKey() throws {
        // Given
        let randomKey = try keychainCenter.createKeyPair()
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertEqual(try keychainCenter.retrieveSensitivePublicKey(), nil, "Precondition failed: Keychain not empty!")

        // When
        try keychainCenter.storeSensitivePublicKey(publicKey: randomPublicKey)

        //Then
        let result = try keychainCenter.retrieveSensitivePublicKey()
        XCTAssertEqual(result, randomPublicKey, "Retrieved public key does not match stored public key!")
    }

    func testCreateKeyPair() throws {
        // Given

        // When
        let randomKeyPair = try keychainCenter.createKeyPair()

        // Then
        //Use public ey to encrypt
        let randomPlainTextData = UUID().uuidString.data(using: .utf8)!
        let randomPubKey = SecKeyCopyPublicKey(randomKeyPair)
        // encrypt private part of sensitive_key
        // encrypt data using: SecKeyCreateEncryptedData using sensitiveKEK
        var error: Unmanaged<CFError>?
        guard let encryptedRandomData = SecKeyCreateEncryptedData(randomPubKey!, .eciesEncryptionStandardX963SHA256AESGCM, randomPlainTextData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        //And secret key to decrypt
        guard let decryptedRandomData = SecKeyCreateDecryptedData(randomKeyPair, .eciesEncryptionStandardX963SHA256AESGCM, encryptedRandomData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        XCTAssertEqual(randomPlainTextData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    func testCreateSecureEnclaveKey() {

    }

}
