//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import LocalAuthentication

class KeychainStorageTests: XCTestCase {

    var keychainStorage: KeychainStorage! = nil
    let derivedPasscode = "foobar23"

    public override func setUp() {
        super.setUp()
        // Given
        keychainStorage = KeychainStorage()
    }

    public override func tearDown() {
        super.tearDown()
        // Is it possible to always have a clean/empty keychain?
        keychainStorage.deleteData(KeychainStorage.derivedPasswordTag)
        keychainStorage.deleteData(KeychainStorage.sensitiveEncryptedPrivateKeyTag)
        keychainStorage.deleteItem(tag: KeychainStorage.sensitivePublicKeyTag)
        keychainStorage.deleteItem(tag: KeychainStorage.sensitiveKekTag)
    }

    func testDeleteData() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try keychainStorage.retrieveEncryptedData(account: KeychainStorage.sensitiveEncryptedPrivateKeyTag), nil, "Precondition failed: Keychain not empty!")
        keychainStorage.storeData(valueData: randomData, account: KeychainStorage.sensitiveEncryptedPrivateKeyTag)

        // When
        keychainStorage.deleteData(KeychainStorage.sensitiveEncryptedPrivateKeyTag)

        //Then
        XCTAssertEqual(try keychainStorage.retrieveEncryptedData(account: KeychainStorage.sensitiveEncryptedPrivateKeyTag), nil, "Deletion failed")
    }

    func testDeleteItem() throws {
        // Given
        let randomKey = try keychainStorage.createKeyPair()
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertEqual(try keychainStorage.retrieveSensitivePublicKey(), nil, "Precondition failed: Keychain not empty!")
        try keychainStorage.storeSensitivePublicKey(publicKey: randomPublicKey)

        // When
        keychainStorage.deleteItem(tag: KeychainStorage.sensitivePublicKeyTag)

        //Then
        XCTAssertEqual(try keychainStorage.retrieveSensitivePublicKey(), nil, "Delete item failed")
    }

    func testStoreAndRetrievePasscode() {
        // Given
        let randomString = UUID().uuidString
        XCTAssertEqual(keychainStorage.retrievePasscode(), nil, "Keychain not empty")

        // When
        keychainStorage.storePasscode(derivedPasscode: randomString)

        //Then
        let result = keychainStorage.retrievePasscode()
        XCTAssertEqual(result, randomString, "Unexpected result: \(result)")
    }

    func testStoreAndRetrieveSensitivePrivateKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try keychainStorage.retrieveEncryptedData(account: KeychainStorage.sensitiveEncryptedPrivateKeyTag), nil, "Precondition failed: Keychain not empty!")

        // When
        keychainStorage.storeData(valueData: randomData, account: KeychainStorage.sensitiveEncryptedPrivateKeyTag)

        //Then
        let result = try keychainStorage.retrieveEncryptedData(account: KeychainStorage.sensitiveEncryptedPrivateKeyTag)
        XCTAssertEqual(result, randomData)
    }

    func testStoreAndRetrieveSensitivePublicKey() throws {
        // Given
        let randomKey = try keychainStorage.createKeyPair()
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertEqual(try keychainStorage.retrieveSensitivePublicKey(), nil, "Precondition failed: Keychain not empty!")

        // When
        try keychainStorage.storeSensitivePublicKey(publicKey: randomPublicKey)

        //Then
        let result = try keychainStorage.retrieveSensitivePublicKey()
        XCTAssertEqual(result, randomPublicKey, "Retrieved public key does not match stored public key!")
    }

    func testCreateKeyPair() throws {
        // Given

        // When
        let randomKeyPair = try keychainStorage.createKeyPair()

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

    func testCreateSecureEnclaveKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        let randomPassword = UUID().uuidString

        // When
        let key = try keychainStorage.createSecureEnclaveKey(useBiometry: false, canChangeBiometry: false, applicationPassword: randomPassword)

        // Then
        // check key is usable
        let decryptedRandomData = try validateKeyIsUsable(key: key, randomData: randomData)
        XCTAssertEqual(randomData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    func testFindSecureEnclaveKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        let randomPassword = UUID().uuidString
        try keychainStorage.createSecureEnclaveKey(useBiometry: false, canChangeBiometry: false, applicationPassword: randomPassword)

        // When
        let key = try keychainStorage.findKey(tag: KeychainStorage.sensitiveKekTag, password: randomPassword)!

        // Then
        // check key is usable
        let decryptedRandomData = try validateKeyIsUsable(key: key, randomData: randomData)
        XCTAssertEqual(randomData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    // this test prompts for biometry on real devices. And it fails if it is canceled. No timeout. This hangs in the touch id prompt.
    // Would fails on Simulator during Key generation.
    // Not sure this test is helpful
    func testFindSecureEnclaveKeyWithBiometry() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        let randomPassword = UUID().uuidString
        guard simulatorCheck() else {
            return
        }
        try keychainStorage.createSecureEnclaveKey(useBiometry: true, canChangeBiometry: false, applicationPassword: randomPassword)

        // When
        let key = try keychainStorage.findKey(tag: KeychainStorage.sensitiveKekTag, password: randomPassword)!

        // Then
        // check key is usable
        let decryptedRandomData = try validateKeyIsUsable(key: key, randomData: randomData)
        XCTAssertEqual(randomData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    // Helper functions
    func validateKeyIsUsable(key: SecKey, randomData: Data) throws -> Data {
        let pubKey = SecKeyCopyPublicKey(key)
        // 2. Encrypt randomData
        var error: Unmanaged<CFError>?
        guard let encryptedRandomData = SecKeyCreateEncryptedData(pubKey!, .eciesEncryptionStandardX963SHA256AESGCM, randomData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // 3. decrypt randomData
        guard let decryptedRandomData = SecKeyCreateDecryptedData(key, .eciesEncryptionStandardX963SHA256AESGCM, encryptedRandomData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        return decryptedRandomData
    }

    private func simulatorCheck() -> Bool {
        LAContext().setCredential("anyPassword".data(using: .utf8), type: .applicationPassword)
    }
}
