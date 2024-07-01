//
//  ImportExportDataController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 29.05.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto

struct SecuredDataFile: Codable {
    enum VERSION: String, Codable {
        case v1 = "1.0"
    }
    enum CODEC: String, Codable {
        case aes256GCM = "aes-256-gcm"
    }
    var version: VERSION = .v1
    var algo: CODEC = .aes256GCM
    var salt: Data
    var rounds: Int
    var data: Data
}

struct SerializedDataFile: Codable {
    enum VERSION: String, Codable {
        case v1 = "1.0"
    }
    
    var version: VERSION = .v1
    var data: SerializedContents
    
    struct SerializedContents: Codable {
        var safes: [SerializedSafe]
        var keys: [SerializedKey]
        var contacts: [SerializedContact]
    }

    struct SerializedSafe: Codable {
        var address: String
        var chain: String
        var name: String
    }

    struct SerializedKey: Codable {
        var address: String
        var name: String
        var type: Int
        var mnemonic: String?
        var key: Data?
        var delegate: String?
        var delegateKey: Data?
        var delegateMnemonic: String?
        var path: String?
        var uuid: String?
        var source: UInt32?
        var wallet: String?
        var connectionURL: String?
        var connectionChainId: Int64?
    }
    
    struct SerializedContact: Codable {
        var address: String
        var name: String
        var chain: String
    }
}

class ImportExportDataController {
    // contains entries if there were any errors during import/export or encrypt/decrypt functions.
    private(set) var logs: [String] = []
    private var registryLoader = AppRegistryLoader()
    
    static let fileExtension = "safedata"
    
    func exportToTemporaryFile(key plaintext: String) async -> URL? {
        logs = []
        let exported = await exportEncrypted(key: plaintext)
        guard let result = exported else {
            return nil
        }
        
        do {
            let data = try JSONEncoder().encode(result)
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory

            let currentDate = Date().formatted(Date.ISO8601FormatStyle())
            let exportID = ProcessInfo().globallyUniqueString
            
            let filebase =  exportID + " " + currentDate + " Wallet App Data"
            let filename = filebase + "." + Self.fileExtension
            
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(filename)
            
            try data.write(to: temporaryFileURL)

            return temporaryFileURL
        } catch {
            logs.append("Failed to export to a file: \(error)")
            return nil
        }
    }
    
    static func removeTemporaryFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func importFromDocumentPicker(url: URL?, key plaintext: String?) async {
        logs = []
        guard let url = url, url.startAccessingSecurityScopedResource() else {
            logs.append("Can't access file")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        var fileContents: Data?
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { fileURL in
            
            guard fileURL.startAccessingSecurityScopedResource() else {
                logs.append("Can't access file")
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            do {
                fileContents = try Data(contentsOf: fileURL)
            } catch {
                logs.append("Failed to read file: \(error)")
            }
        }
        
        guard let data = fileContents, let plaintext = plaintext else {
            return
        }
        
        do {
            let file = try JSONDecoder().decode(SecuredDataFile.self, from: data)
            await importEncrypted(file: file, key: plaintext)
        } catch {
            logs.append("Failed to import: \(error)")
        }
    }
    
    func exportEncrypted(key: String) async -> SecuredDataFile? {
        let file = await export()
        let result = encrypt(file: file, key: key)
        return result
    }
    
    @MainActor
    func importEncrypted(file: SecuredDataFile, key plaintext: String) async {
        if let dataFile = decrypt(file: file, key: plaintext) {
            await importData(file: dataFile)
        }
    }
    
    func deriveKey(from plaintext: String, salt: Data, rounds: Int) -> Data? {
        var salt = salt.bytes
        var derivedKey = [UInt8](repeating: 0, count: 32)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            plaintext,
            plaintext.lengthOfBytes(using: .utf8),
            &salt,
            salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            UInt32(rounds),
            &derivedKey,
            derivedKey.count)
        guard status == kCCSuccess else {
            logs.append("Failed to derive a key. Error code \(status)")
            return nil
        }
        let result = Data(derivedKey)
        return result
    }

    func encrypt(file: SerializedDataFile, key plaintext: String) -> SecuredDataFile? {
        let salt = Data.randomBytes(count: 32)
        let rounds = 100000
        guard let keyData = deriveKey(from: plaintext, salt: salt, rounds: rounds) else {
            return nil
        }
        do {
            let key = SymmetricKey(data: keyData)
            let input = try JSONEncoder().encode(file)
            let output = try AES.GCM.seal(input, using: key).combined!
            let result = SecuredDataFile(version: .v1, algo: .aes256GCM, salt: salt, rounds: rounds, data: output)
            return result
        
        } catch {
            logs.append("Error during encryption: \(error)")
            return nil
        }
    }
    
    func decrypt(file: SecuredDataFile, key plaintext: String) -> SerializedDataFile? {
        guard file.version == .v1, file.algo == .aes256GCM else {
            logs.append("Unrecognized file version or encryption algorithm")
            return nil
        }
        guard let keyData = deriveKey(from: plaintext, salt: file.salt, rounds: file.rounds) else {
            return nil
        }
        do {
            let key = SymmetricKey(data: keyData)
            let input = file.data
            let output = try AES.GCM.open(AES.GCM.SealedBox(combined: input), using: key)
            let dataFile = try JSONDecoder().decode(SerializedDataFile.self, from: output)
            return dataFile
        } catch CryptoKitError.authenticationFailure {
            logs.append("Failed to decrypt: wrong password.")
            return nil
        } catch {
            logs.append("Error during decryption: \(error)")
            return nil
        }
    }
    
    // Assumptions:
    // chains exist in the database;
    // only deployed safes are exported
    // there might already exist objects for the same entities (safes, contacts, or keys) - data will be skipped
    // erroneous objects are skipped and errors are logged and reported to user
    func export() async -> SerializedDataFile {
        // safes
        let safes: [SerializedDataFile.SerializedSafe] = Safe.all.filter { $0.safeStatus == .deployed }.map { safe in
            SerializedDataFile.SerializedSafe(
                address: safe.address!,
                chain: safe.chain!.id!,
                name: safe.name!
            )
        }

        // keys
        
        let infos = ((try? KeyInfo.all()) ?? [])
        var keys: [SerializedDataFile.SerializedKey] = []
        
        for key in infos {
            var data = SerializedDataFile.SerializedKey(address: key.address.checksummed, name: key.name!, type: key.keyType.rawValue)
            
            // delegate key
            do {
                let dk = try await key.pushNotificationSigningKey()
                data.delegate = key.delegateAddressString
                data.delegateMnemonic = dk?.mnemonic
                data.delegateKey = dk?.keyData
            } catch {
                logs.append("Export of key named '\(key.name!)' with address \(key.address): " +
                            "could not get delegate key because of error: \(error)")
            }
            
            // type-dependent metadata
            switch key.keyType {
            case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
                // private key
                do {
                    let pk = try await key.signingKey()
                    data.mnemonic = pk?.mnemonic
                    data.key = pk?.keyData
                } catch {
                    logs.append("Export of key named '\(key.name!)' with address \(key.address): " +
                                "could not get private key because of error: \(error)")
                }
                
            case .walletConnect:
                data.wallet = key.wallet?.id
                data.connectionURL = key.walletConnections?.first?.connectionURL
                data.connectionChainId = key.walletConnections?.first?.chainId
                
            case .ledgerNanoX:
                guard let rawMetadata = key.metadata,
                      let metadata = KeyInfo.LedgerKeyMetadata.from(data: rawMetadata) else {
                    logs.append("Skipping key named '\(key.name!)' with address \(key.address): " +
                                "could not load ledger key metadta")
                    continue
                }
                data.path = metadata.path
                data.uuid = metadata.uuid.uuidString
                
            case .keystone:
                guard let rawMetadata = key.metadata,
                      let metadata = KeyInfo.KeystoneKeyMetadata.from(data: rawMetadata) else {
                    logs.append("Skipping key named '\(key.name!)' with address \(key.address): " +
                                "could not load keystone key metadta")
                    continue
                }
                data.path = metadata.path
                data.source = metadata.sourceFingerprint
            }
            
            keys.append(data)
        }
        
        // contacts
            // all address book entries and associated chains
            // map to serialized contact
        let contacts: [SerializedDataFile.SerializedContact] = AddressBookEntry.all.map { entry in
            SerializedDataFile.SerializedContact(
                address: entry.address!,
                name: entry.name!,
                chain: entry.chain!.id!
            )
        }
        
        // data file contents
        let file = SerializedDataFile(version: .v1, data: SerializedDataFile.SerializedContents(
            safes: safes,
            keys: keys,
            contacts: contacts))
        return file
    }
    
    @MainActor
    func importData(file: SerializedDataFile) async {
        guard file.version == .v1 else {
            logs.append("Unsupported file version \(file.version). " +
                        "Expected version '\(SerializedDataFile.VERSION.v1)'.")
            return
        }
        
        
        let MAX_NAME_LENGTH = 500
        
        // chains

        func loadChains() async -> [SCGModels.Chain] {
            await withCheckedContinuation { continuation in
                App.shared.clientGatewayService.asyncChains { result in
                    do {
                        let results = try result.get()
                        continuation.resume(returning: results.results)
                    } catch {
                        continuation.resume(returning: [])
                    }
                }
            }
        }
        
        let chains = await loadChains()
        for chain in chains {
            Chain.createOrUpdate(chain)
        }
        NotificationCenter.default.post(name: .chainInfoChanged, object: nil)

        
        // safes
        let safes: [SerializedDataFile.SerializedSafe] = file.data.safes
        
        func safeInfo(address: Address, chain: Chain) async -> SCGModels.SafeInfoExtended? {
            await withCheckedContinuation { continuation in
                _ = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: address, chainId: chain.id!) { result in
                    do {
                        let info = try result.get()
                        continuation.resume(returning: info)
                    } catch {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        for safe in safes {
            // validate address and chain
            guard let address = Address(str(safe.address)) else {
                logs.append("Skipped safe with name '\(safe.name)': " +
                            "address \(safe.address) is not a valid address value.")
                continue
            }
            guard let chain = Chain.by(str(safe.chain)) else {
                logs.append("Skipped safe with name '\(safe.name)': " +
                            "chain with id '\(safe.chain) is not found in the app data.")
                continue
            }
            // de-duplicate
            guard !Safe.exists(address.checksummed, chainId: chain.id!) else {
                continue
            }
            // verify with backend
            guard let info = await safeInfo(address: address, chain: chain),
                  let version = info.version,
                  App.shared.gnosisSafe.isSupported(version) else {
                logs.append("Skipped safe with name '\(safe.name)': " +
                            "can't use the address \(safe.address) because either safe does not exist, or " +
                            "has an unsupported contract version, " +
                            "or there were issues with Internet connection.")
                continue
            }
            
            let name = str(safe.name, MAX_NAME_LENGTH)
            
            let cdSafe = Safe.create(address: address.checksummed, version: version, name: name, chain: chain)
            cdSafe.update(from: info)

            App.shared.notificationHandler.safeAdded(address: address)

        }
        
        // keys
        let keys: [SerializedDataFile.SerializedKey] = file.data.keys
        
        do {
            if keys.contains(where: { $0.type == KeyType.walletConnect.rawValue }) {
                registryLoader = AppRegistryLoader()
                try await registryLoader.loadRegistry()
            }
        } catch {
            logs.append("Could not load wallet connect wallet registry: \(error)")
        }
        
        
        for key in keys {
            guard let address = Address(str(key.address)) else {
                logs.append("Skipped key with name '\(key.name)': " +
                            "address \(key.address) is not a valid address value.")
                continue
            }
            guard let keyType = KeyType(rawValue: key.type) else {
                logs.append("Skipped key with name '\(key.name)': " +
                            "type \(key.type) is not a valid value.")
                continue
            }
            let name = str(key.name, MAX_NAME_LENGTH)
            
            var keyInfo: KeyInfo? 
            
            do {
                keyInfo = try KeyInfo.firstKey(address: address)
            } catch {
                logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                            "could not access database: \(error).")
                continue
            }
            
            if keyInfo == nil {
                // non-existing key
                var didAdd = false
                
                switch keyType {
                case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
                    if let keyData = key.key {
                        var privateKey: PrivateKey
                        
                        do {
                            privateKey = try PrivateKey(data: keyData)
                        } catch {
                            logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                        "could not create a private key: \(error).")
                            continue
                        }
                        
                        privateKey.mnemonic = key.mnemonic
                        
                        var adjustedType = KeyType.socialKeyTypes.contains(keyType) ? KeyType.deviceImported : keyType
                        
                        didAdd = OwnerKeyController.importKey(privateKey, name: name, type: adjustedType, isDerivedFromSeedPhrase: privateKey.mnemonic != nil)
                        
                        if didAdd, let item = try? KeyInfo.keys(addresses: [address]).first {
                            item.backedup = true
                            item.save()
                        }
                    }
                    
                    if !didAdd {
                        logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                    "could not find a private key data.")
                        continue
                    }
                    
                case .walletConnect:
                    if let wallet = key.wallet,
                        let connectionURL = key.connectionURL,
                        let connectionChainId = key.connectionChainId,
                        let cdEntry = CDWCAppRegistryEntry.entry(by: wallet),
                        let webConnURL = (WebConnectionURL(stringV2: connectionURL) ?? WebConnectionURL(string: connectionURL))
                    {
                        let webEntry = WCAppRegistryRepository().entry(from: cdEntry)
                        let webConn = WebConnectionController.shared.createWalletConnection(from: webConnURL, info: webEntry)
                        webConn.chainId = Int(connectionChainId)
                        didAdd = OwnerKeyController.importKey(connection: webConn, wallet: webEntry, name: name)
                    } else if let wallet = key.wallet,
                              let cdEntry = CDWCAppRegistryEntry.entry(by: wallet)
                    {
                        let webEntry = WCAppRegistryRepository().entry(from: cdEntry)
                        didAdd = OwnerKeyController.importKey(connection: nil, wallet: webEntry, name: name, address: address)
                    }
                    
                    if !didAdd {
                        logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                    "could not create valid wallet connect connection.")
                        continue
                    }
                case .ledgerNanoX:
                    if let path = key.path, let uuid = key.uuid {
                        didAdd = OwnerKeyController.importKey(
                            ledgerDeviceUUID: UUID(uuidString: str(uuid))!,
                            path: str(path),
                            address: address,
                            name: name)
                    }
                    
                    if !didAdd {
                        logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                    "could not create ledger metadata.")
                        continue
                    }
                    
                case .keystone:
                    if let path = key.path, let source = key.source {
                        didAdd = OwnerKeyController.importKey(
                            keystone: address, path: str(path), name: name, sourceFingerprint: source)
                    }
                    
                    if !didAdd {
                        logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                    "could not create keystone metadata.")
                        continue
                    }
                }
                
                do {
                    keyInfo = try KeyInfo.firstKey(address: address)
                } catch {
                    logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                "could not find created key in the database: \(error).")
                    continue
                }
                
            } else {
                // if existing KeyInfo entry but missing a private key in Keychain
                do {
                    let signingKey = try await keyInfo?.signingKey()
                    if signingKey == nil, let keyData = key.key {
                        var privateKey = try PrivateKey(data: keyData)
                        privateKey.mnemonic = key.mnemonic
                        try privateKey.save()
                    }
                } catch {
                    logs.append("Skipped key with name '\(key.name)' and address \(address): " +
                                "could not set up a private key: \(error).")
                    continue
                }
            }
            
            guard let info = keyInfo else {
                logs.append("Skipped key with name '\(key.name)': " +
                            "could not create or find a key with address \(key.address).")
                continue
            }
            
            // if missing a delegate key
            do {
                let delegateSigningKey = try await info.pushNotificationSigningKey()
                if delegateSigningKey == nil,
                   let delegate = key.delegate.flatMap({ Address(str($0)) }),
                   info.delegateAddress == nil || info.delegateAddress == delegate,
                   let keyData = key.delegateKey
                {
                    var delegateKey = try PrivateKey(data: keyData)
                    delegateKey.mnemonic = key.delegateMnemonic
                    try delegateKey.save(protectionClass: .data)
                    info.delegateAddress = delegate
                    info.save()
                    NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)
                    App.shared.notificationHandler.signingKeyUpdated()
                }
            } catch {
                logs.append("Key with name '\(key.name)' and address \(address): " +
                            "could not set up a delegate key: \(error).")
                continue
            }
        }
        
        // contacts
        let contacts: [SerializedDataFile.SerializedContact] = file.data.contacts
    
        for contact in contacts {
            guard let address = Address(str(contact.address)) else {
                logs.append("Skipped address book entry for name '\(contact.name)': " +
                            "address \(contact.address) is not a valid address value.")
                continue
            }
            guard let chain = Chain.by(str(contact.chain)) else {
                logs.append("Skipped address book entry for name '\(contact.name)': " +
                            "chain with id '\(contact.chain) is not found in the app data.")
                continue
            }
            let name = str(contact.name, MAX_NAME_LENGTH)
            
            AddressBookEntry.addOrUpdate(address.checksummed, chain: chain, name: name)
        }
    }
}

// pre-load app registry
class AppRegistryLoader: WCRegistryControllerDelegate {
    
    var controller = WCRegistryController()
    var completion: ((Result<Void, Error>) -> Void)?
    
    init() {
        controller.delegate = self
    }
    
    func start() {
        controller.loadData()
    }
    
    func didUpdate(controller: WCRegistryController) {
        completion?(.success(()))
    }
    
    func didFailToLoad(controller: WCRegistryController, error: any Error) {
        completion?(.failure(error))
    }
    
    @MainActor
    func loadRegistry() async throws {
        try await withCheckedThrowingContinuation { [unowned self] continuation in
            completion = { result in
                do {
                    _ = try result.get()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            start()
        }
    }
}

fileprivate func str(_ v: String, _ len: Int? = nil) -> String {
    let r = v.trimmingCharacters(in: .whitespacesAndNewlines)
    if let len = len {
        return String(r.prefix(len))
    } else {
        return r
    }
}
