//
// Created by Dirk Jäckel on 09.01.23.
// Copyright (c) 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class DataKeyStore: EncryptedStore {
    private let store: KeychainItemStore

    static let dataPublicKeyTag = "global.safe.dataPublicKeyTag"
    static let dataPublicKEKTag = "global.safe.dataPublicKEKTag"
    static let dataPrivateKEKTag = "global.safe.dataPrivateKEKTag"
    static let dataEncryptedPrivateKeyTag = "global.safe.data.private.key.as.encrypted.data"
    static let storedPasswordTag = "global.safe.data.password.as.data"

    init(_ store: KeychainItemStore) {
        self.store = store
    }

    func isInitialized() -> Bool {
        do {
            return try store.find(.ecPubKey(tag: DataKeyStore.dataPublicKeyTag)) != nil
        } catch {
            LogService.shared.error("DataKeyStore is not initialized", error: error)
            return false
        }
    }

    func initializeKeyStore() throws {
        try initialize()
    }

    func initialize() throws {
        // 1. create password
        let passwordData = createRandomBytes(32)
        // store password
        let passItem = KeychainItem.generic(
                id: DataKeyStore.storedPasswordTag,
                service: ProtectionClass.data.service(),
                data: passwordData
        )
        try store.create(passItem)

        // 2. create kek
        // kek security attributes are
        // based on the user's security settings
        // and on the defaults
        // that is application/module-specific
        let kekItem = KeychainItem.enclaveKey(
                tag: DataKeyStore.dataPrivateKEKTag,
                password: passwordData,
                access: [.applicationPassword]
        )
        let keyEncryptionKey: SecKey = try store.create(kekItem) as! SecKey

        // 3. create key pair
        let privateKeyItem = KeychainItem.ecKeyPair // is it a pair though? also, why no tag? because it is not stored directly.
        let dataKey: SecKey = try store.create(privateKeyItem) as! SecKey

        let encryptedPK = try Data(secKey: dataKey).encrypt(publicKey: keyEncryptionKey.publicKey())

        // store key pair
        // store encrypted private key
        let encryptedPrivateKeyItem = KeychainItem.generic(
                id: DataKeyStore.dataEncryptedPrivateKeyTag,
                service: ProtectionClass.data.service(),
                data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

        // store public key
        let pubKeyItem = KeychainItem.ecPubKey(
                tag: DataKeyStore.dataPublicKeyTag,
                publicKey: dataKey.publicKey()
        )
        try store.create(pubKeyItem)
    }

    private func createRandomBytes(_ amount: Int) -> Data? {
        var bytes: [UInt8] = .init(repeating: 0, count: amount)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            return nil
        }
        return Data(bytes)
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws {
        //1. create key from Data
        let privateKey = try PrivateKey(data: ethPrivateKey)

        // 2. find public data key
        let pubKey = try store.find(.ecPubKey(tag: DataKeyStore.dataPublicKeyTag)) as! SecKey

        // 3. encrypt private key with public sedatansitive key
        var error: Unmanaged<CFError>?

        let encryptedSigningKey = try ethPrivateKey.encrypt(publicKey: pubKey)

        // 4. store encrypted blob in the keychain
        let address = privateKey.address
        try store.create(KeychainItem.generic(id: id.id, service: id.protectionClass.service(), data: encryptedSigningKey))
    }

    func delete(address: Address) throws {
        try store.delete(KeychainItem.generic(id: address.checksummed, service: ProtectionClass.data.service()))
    }

    func find(dataID: DataID, password: String?) throws -> EthPrivateKey? {
        // Get encrypted signing key
        guard let encryptedSigningKey = try store.find(KeychainItem.generic(id: dataID.id, service: dataID.protectionClass.service())) as? Data else {
            return nil
        }
        // If no password given retrieve the password from store
        let storedPassword = try store.find(KeychainItem.generic(id: DataKeyStore.storedPasswordTag, service: ProtectionClass.data.service())) as! Data?
        let password = password != nil ? password?.data(using: .utf8) : storedPassword

        // Get access to secure enclave key
        let dataKEK = try store.find(KeychainItem.enclaveKey(tag: DataKeyStore.dataPrivateKEKTag, password: password)) as! SecKey

        // Get access to encrypted data key
        let encryptedDataKey = try store.find(KeychainItem.generic(id: DataKeyStore.dataEncryptedPrivateKeyTag, service: ProtectionClass.data.service())) as? Data
        // Decrypt data Key
        let decryptedDataKeyData = try encryptedDataKey?.decrypt(privateKey: dataKEK)

        // Restore data key from Data
        var error: Unmanaged<CFError>?
        guard let decryptedDataKey: SecKey = SecKeyCreateWithData(decryptedDataKeyData! as CFData, try KeychainItem.ecKeyPair.creationAttributes(), &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
        // Decrypt signer key with data key
        return try encryptedSigningKey.decrypt(privateKey: decryptedDataKey)    }

    func changePassword(from oldPassword: String, to newPassword: String) {
    }

    func changeSettings() {
        fatalError("deprecated")
    }
}
