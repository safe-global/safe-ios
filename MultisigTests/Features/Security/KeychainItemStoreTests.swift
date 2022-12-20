//
// Created by Dirk Jäckel on 14.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import LocalAuthentication

class KeychainItemStoreTests: XCTestCase {

    var kciStore: KeychainItemStore! = nil
    let derivedPasscode = "foobar23"

    public override func setUp() {
        super.setUp()
        // Given
        kciStore = KeychainItemStore(KeychainStore())
    }

    public override func tearDown() {
        super.tearDown()
        // Is it possible to always have a clean/empty keychain?
        try! kciStore.delete(.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service()))
        try! kciStore.delete(.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service()))
        try! kciStore.delete(.ecPubKey())
        try! kciStore.delete(.enclaveKey())
    }

    func testDeleteItem() throws {
        // Given
        let randomKey = try kciStore.create(KeychainItem.ecKeyPair) as! SecKey
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertTrue(try kciStore.find(KeychainItem.ecPubKey()) == nil, "Precondition failed: Keychain not empty!!")
        try kciStore.create(.ecPubKey(publicKey: randomPublicKey))

        // When
        try kciStore.delete(.ecPubKey())

        //Then
        XCTAssertTrue(try kciStore.find(KeychainItem.ecPubKey()) == nil, "Delete item failed")
    }

    func testDeleteItemIgnoreNotFound() throws {
        // Given
        XCTAssertTrue(try kciStore.find(KeychainItem.ecPubKey()) == nil, "Precondition failed: Keychain not empty!!")

        // When
        try kciStore.delete(.ecPubKey())

        //Then
        XCTAssertTrue(try kciStore.find(KeychainItem.ecPubKey()) == nil, "Delete item failed")
    }

    func testStoreAndRetrievePasscode() throws {
        // Given
        let randomString = UUID().uuidString
        let passCodeData = try kciStore.find(KeychainItem.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service())) as! Data?
        XCTAssertEqual(passCodeData, nil, "Keychain not empty")

        // When
        try kciStore.create(KeychainItem.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service(), data: randomString.data(using: .utf8)))

        //Then
        let result = try kciStore.find(KeychainItem.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service())) as! Data?
        XCTAssertEqual(result, randomString.data(using: .utf8), "Unexpected result: \(result)")
    }

    func testStoreAndRetrieveSensitivePrivateKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        XCTAssertEqual(try kciStore.find(.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service())) as! Data?, nil, "Precondition failed: Keychain not empty!")

        // When
        try kciStore.create(.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service(), data: randomData))

        //Then
        let result = try kciStore.find(.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service())) as! Data?
        XCTAssertEqual(result, randomData)
    }

    func testStoreAndRetrieveSensitivePublicKey() throws {
        // Given
        let randomKey = try kciStore.create(KeychainItem.ecKeyPair) as! SecKey

        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertTrue(try kciStore.find(KeychainItem.ecPubKey()) == nil, "Precondition failed: Keychain not empty!")

        // When
        try kciStore.create(KeychainItem.ecPubKey(publicKey: randomPublicKey))

        //Then
        let result = try kciStore.find(KeychainItem.ecPubKey()) as! SecKey?
        XCTAssertTrue(result == randomPublicKey, "Retrieved public key does not match stored public key!")
    }

    func testStoreDeletesFirst() throws {
        // Given
        let randomKey = try kciStore.create(KeychainItem.ecKeyPair) as! SecKey
        let randomPublicKey = SecKeyCopyPublicKey(randomKey)!
        XCTAssertEqual(try kciStore.find(KeychainItem.ecPubKey()) as! SecKey?, nil, "Precondition failed: Keychain not empty!")

        // When
        try kciStore.create(.ecPubKey(publicKey: randomPublicKey))

        // This throws an error if storeItem doesn't try to delete the item first
        try kciStore.create(.ecPubKey(publicKey: randomPublicKey))

        //Then
    }

    func testCreateKeyPair() throws {
        // Given

        // When
        let randomKeyPair = try kciStore.create(KeychainItem.ecKeyPair) as! SecKey

        // Then
        // Use public key to encrypt
        let randomPlainTextData = UUID().uuidString.data(using: .utf8)!
        let randomPubKey = SecKeyCopyPublicKey(randomKeyPair)
        // encrypt private part of sensitive_key
        // encrypt data using: SecKeyCreateEncryptedData using sensitiveKEK
        var error: Unmanaged<CFError>?
        guard let encryptedRandomData = SecKeyCreateEncryptedData(randomPubKey!, .eciesEncryptionStandardX963SHA256AESGCM, randomPlainTextData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // And secret key to decrypt
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
        let key = try kciStore.create(KeychainItem.enclaveKey(
                password: randomPassword.data(using: .utf8),
                access: [.applicationPassword])
        ) as! SecKey

        // Then
        // check key is usable
        let decryptedRandomData = try validateKeyIsUsable(key: key, randomData: randomData)
        XCTAssertEqual(randomData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    func testFindSecureEnclaveKey() throws {
        // Given
        let randomData = UUID().uuidString.data(using: .utf8)!
        let randomPassword = UUID().uuidString
        try kciStore.create(KeychainItem.enclaveKey(
                password: randomPassword.data(using: .utf8),
                access: [.applicationPassword])
        ) as! SecKey

        // When
        let key = try kciStore.find(KeychainItem.enclaveKey(password: randomPassword.data(using: .utf8))) as! SecKey

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
        try kciStore.create(KeychainItem.enclaveKey(
                password: randomPassword.data(using: .utf8),
                access: [.applicationPassword, .userPresence])
        ) as! SecKey

        // When
        let key = try kciStore.find(.enclaveKey(password: randomPassword.data(using: .utf8))) as! SecKey

        // Then
        // check key is usable
        let decryptedRandomData = try validateKeyIsUsable(key: key, randomData: randomData)
        XCTAssertEqual(randomData, decryptedRandomData, "Plaintext not equal decrypted data!")
    }

    // Helper functions
    func validateKeyIsUsable(key: SecKey, randomData: Data) throws -> Data {
        let pubKey = SecKeyCopyPublicKey(key)
        // Encrypt randomData
        var error: Unmanaged<CFError>?
        guard let encryptedRandomData = SecKeyCreateEncryptedData(pubKey!, .eciesEncryptionStandardX963SHA256AESGCM, randomData as CFData, &error) as? Data else {
            LogService.shared.error("Could not encrypt random data")
            throw error!.takeRetainedValue() as Error
        }
        // Decrypt encrypted randomData
        guard let decryptedRandomData = SecKeyCreateDecryptedData(key, .eciesEncryptionStandardX963SHA256AESGCM, encryptedRandomData as CFData, &error) as? Data else {
            LogService.shared.error("Could not decrypt random data")
            throw error!.takeRetainedValue() as Error
        }
        return decryptedRandomData
    }

    private func simulatorCheck() -> Bool {
        LAContext().setCredential("anyPassword".data(using: .utf8), type: .applicationPassword)
    }
}
