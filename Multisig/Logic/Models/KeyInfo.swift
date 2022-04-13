//
//  KeyInfo.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 3/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import Web3
import WalletConnectSwift

/// Enum for storing key type in the persistence store. The order of existing items should not be changed.
enum KeyType: Int, CaseIterable {
    case deviceImported = 0
    case deviceGenerated = 1
    case walletConnect = 2
    case ledgerNanoX = 3
}

extension KeyInfo {
    /// Blockchain address that this key controls
    var address: Address {
        get { addressString.flatMap(Address.init) ?? Address.zero}
        set { addressString = newValue.checksummed }
    }

    var delegateAddress: Address? {
        get { delegateAddressString.flatMap(Address.init) }
        set { delegateAddressString = newValue?.checksummed }
    }

    var keyType: KeyType {
        get { KeyType(rawValue: Int(type)) ?? .deviceImported }
        set { type = Int16(newValue.rawValue) }
    }

    var needsBackup: Bool {
        keyType == .deviceGenerated && !backedup
    }

    var displayName: String {
        name ?? "Key \(address.ellipsized())"
    }

    var connectedAsDapp: Bool {
        guard keyType == .walletConnect, let connections = walletConnections else { return false }
        let result = !connections.isEmpty
        return result
    }

    var walletConnections: [CDWCConnection]? {
        connections?.compactMap { $0 as? CDWCConnection }
            .filter {
                $0.localPeer?.role == WebConnectionPeerRole.dapp.rawValue &&
                        $0.remotePeer?.role == WebConnectionPeerRole.wallet.rawValue
            }
    }

    struct LedgerKeyMetadata: Codable {
        let uuid: UUID
        let path: String

        var data: Data {
            try! JSONEncoder().encode(self)
        }

        static func from(data: Data) -> Self? {
            try? JSONDecoder().decode(Self.self, from: data)
        }
    }

    static func name(address: Address) -> String? {
        guard let keyInfo = try? KeyInfo.keys(addresses: [address]).first else { return nil }
        return keyInfo.name
    }

    /// Returns number of existing key infos
    static func count(_ type: KeyType? = nil) -> Int {
        do {
            let items = try KeyInfo.all()
            if let type = type {
                return items.filter({ keyInfo in keyInfo.keyType == type }).count
            } else {
                return items.count
            }
        } catch {
            LogService.shared.error("Failed to fetch safe count: \(error)")
            return 0
        }
    }

    static func keysWithoutBackup() -> [KeyInfo] {
        (try? all().filter { KeyType(rawValue: Int($0.type))! == .deviceGenerated && $0.backedup == false }) ?? []
    }

    /// Return the list of KeyInfo sorted alphabetically by name
    static func all() throws -> [KeyInfo] {
        let context = App.shared.coreDataStack.viewContext
        let fr = KeyInfo.fetchRequest().all()
        let items = try context.fetch(fr)
        return items
    }

    static func owners(safe: Safe) -> [KeyInfo] {
        guard let owners = safe.ownersInfo?.compactMap ({ $0.address } ) else { return [] }

        return (try? KeyInfo.keys(addresses: owners)) ?? []
    }

    static func keys(types: [KeyType]) throws -> [KeyInfo] {
        try all().filter { types.contains(KeyType(rawValue: Int($0.type))!) }
    }

    /// This will return a list of KeyInfo for the addresses that it finds in the app.
    /// At most one key info per address will be returned.
    /// - Parameter addresses: all the infos for the same address
    /// - Returns: list of key information
    static func keys(addresses: [Address]) throws -> [KeyInfo] {
        let context = App.shared.coreDataStack.viewContext
        return try addresses.compactMap { address in
            let fr = KeyInfo.fetchRequest().by(address: address)
            let items = try context.fetch(fr)
            return items.first
        }
    }

    static func firstKey(address: Address) throws -> KeyInfo? {
        try keys(addresses: [address]).first
    }

    /// Returns private keys found by the addresses. The multiple private keys option is needed when we want to sign the "push notification" payload with all of the keys available in the app.
    /// At most one key per address is returned.
    /// 
    /// - Parameter addresses: which addresses you want to get keys?
    /// - Throws: in case of underlying errors
    /// - Returns: private keys for the addresses that were found.
    static func privateKeys(addresses: [Address]) throws -> [PrivateKey] {
        try addresses.compactMap { address in
            try PrivateKey.key(address: address)
        }
    }

    /// Will add a new key to the Keychain/Secure storage and save the key info in the persistence store.
    /// - Parameters:
    ///   - address: address of the imported key
    ///   - name: name of the imported key
    ///   - privateKey: private key to save
    @discardableResult
    static func `import`(address: Address, name: String, privateKey: PrivateKey) throws -> KeyInfo {
        let context = App.shared.coreDataStack.viewContext

        let fr = KeyInfo.fetchRequest().by(address: address)
        let item: KeyInfo

        if (try context.fetch(fr).first) != nil {
            throw GSError.DuplicateKey()
        } else {
            item = KeyInfo(context: context)
        }

        item.address = address
        item.name = name
        item.keyID = privateKey.id
        item.keyType = privateKey.mnemonic == nil ? .deviceImported : .deviceGenerated
        item.backedup = false

        item.save()
        try privateKey.save()

        return item
    }

    @discardableResult
    static func `import`(connection: WebConnection, wallet: WCAppRegistryEntry?, name: String) throws -> KeyInfo? {
        guard let address = connection.accounts.first else {
            return nil
        }

        let context = App.shared.coreDataStack.viewContext

        let fr = KeyInfo.fetchRequest().by(address: address)
        let item: KeyInfo

        if (try context.fetch(fr).first) != nil {
            throw GSError.DuplicateKey()
        } else {
            item = KeyInfo(context: context)
            item.name = name
        }

        item.address = address
        item.keyID = "walletconnect:\(address.checksummed)"
        item.keyType = .walletConnect

        if let cdConnection = CDWCConnection.connection(by: connection.connectionURL.absoluteString) {
            item.addToConnections(cdConnection)
        }

        if let wallet = wallet, let cdRegistryEntry = CDWCAppRegistryEntry.entry(by: wallet.id) {
            item.wallet = cdRegistryEntry
        }

        item.save()

        return item
    }

    /// Will save the key info from Ledger device in the persistence store.
    /// - Parameters:
    ///   - ledgerDeviceUUID: device UUID
    ///   - path: key derivation path
    ///   - address: key address
    ///   - name: key name
    @discardableResult
    static func `import`(ledgerDeviceUUID: UUID, path: String, address: Address, name: String) throws -> KeyInfo? {
        let context = App.shared.coreDataStack.viewContext

        let fr = KeyInfo.fetchRequest().by(address: address)
        let item: KeyInfo

        if (try context.fetch(fr).first) != nil {
            throw GSError.DuplicateKey()
        } else {
            item = KeyInfo(context: context)
            item.name = name
        }

        item.address = address
        item.keyID = "ledger:\(address.checksummed)"
        item.keyType = .ledgerNanoX
        item.metadata = LedgerKeyMetadata(uuid: ledgerDeviceUUID, path: path).data

        item.save()

        return item
    }


    @discardableResult
    static func update(keyInfo: KeyInfo, connection: WebConnection) throws -> KeyInfo? {
        guard let address = connection.accounts.first else {
            return nil
        }

        let context = App.shared.coreDataStack.viewContext

        if let cdConnection = CDWCConnection.connection(by: connection.connectionURL.absoluteString) {
            keyInfo.addToConnections(cdConnection)
        }

        keyInfo.save()

        return keyInfo
    }

    /// Renames the key with a different name
    /// - Parameter newName: new name for the key. Not empty.
    func rename(newName: String) {
        assert(!newName.isEmpty, "name must not be empty")
        name = newName
        save()
    }

    /// Delete all of the keys stored
    static func deleteAll() throws {
        try all().forEach { try $0.delete() }
    }

    /// Saves the key to the persistent store
    func save() {
        App.shared.coreDataStack.saveContext()
    }

    func rollback() {
        App.shared.coreDataStack.rollback()
    }

    /// Will delete the key info and the stored private key
    /// - Throws: in case of underlying error
    func delete() throws {
        if let keyID = keyID, keyType == .deviceImported || keyType == .deviceGenerated {
            try PrivateKey.remove(id: keyID)
        }
        App.shared.coreDataStack.viewContext.delete(self)
        save()
    }

    func privateKey() throws -> PrivateKey? {
        guard let keyID = keyID else { return nil }
        return try PrivateKey.key(id: keyID)
    }

    func delegatePrivateKey() throws -> PrivateKey? {
        guard let addressString = delegateAddressString, let address = Address(addressString) else { return nil }
        return try PrivateKey.key(address: address)
    }

    func pushNotificationSigningKey() throws -> PrivateKey? {
        if let key = (try? privateKey()) { return key }
        return try? delegatePrivateKey()
    }
}

extension NSFetchRequest where ResultType == KeyInfo {
    /// all, sorted by name, ascending
    func all() -> Self {
        sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))),
            NSSortDescriptor(key: "addressString", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        ]
        return self
    }
}
