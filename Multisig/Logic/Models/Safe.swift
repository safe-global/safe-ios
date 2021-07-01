//
//  SafeMO.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import FirebaseAnalytics

fileprivate var cachedNames = [AddressString: String]()

extension Safe: Identifiable {

    var isSelected: Bool { selection != nil }

    var hasAddress: Bool { address?.isEmpty == false }

    var displayAddress: String { address! }

    var addressValue: Address { Address(address!)! }

    var browserURL: URL { Self.browserURL(address: displayAddress) }

    var displayName: String { name.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled Safe" }

    var displayENSName: String { ensName ?? "" }

    var isReadOnly: Bool {
        guard let owners = ownersInfo else { return false }
        if let keys = try? KeyInfo.keys(addresses: owners.map(\.address)), !keys.isEmpty {
            return false
        } else {
            return true
        }
    }

    // this value is for contract versions 1.0.0 and 1.1.1 (probably for later versions as well)
    static let DefaultEIP712SafeAppTxTypeHash =
        Data(ethHex: "0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8")

    static let DefaultEIP712SafeAppDomainSeparatorTypeHash =
        Data(ethHex: "0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749")

    static func domainData(for safe: AddressString) -> Data {
        Safe.DefaultEIP712SafeAppDomainSeparatorTypeHash + safe.data32
    }

    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Safe.fetchRequest().all())) ?? 0
    }

    static var all: [Safe] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Safe.fetchRequest().all())) ?? []
    }

    static func by(address: String) -> Safe? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().by(address: address)
        return try? context.fetch(fr).first
    }

    static func updateCachedNames() {
        guard let safes = try? Safe.getAll() else { return }
        cachedNames = safes.reduce(into: [AddressString: String]()) { names, safe in
            names[AddressString(safe.address!)!] = safe.name!
        }
    }

    static func cachedName(by address: AddressString) -> String? {
        cachedNames[address]
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        additionDate = Date()
    }

    func select() {
        let selection = Selection.current()
        selection.safe = self
        App.shared.coreDataStack.saveContext()
        NotificationCenter.default.post(name: .selectedSafeChanged, object: nil)
    }

    static func getSelected() throws -> Safe? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = Safe.fetchRequest().selected()
            let safe = try context.fetch(fr).first
            return safe
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func getAll() throws -> [Safe] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = Safe.fetchRequest().all()
            let safes = try context.fetch(fr)
            return safes
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func browserURL(address: String) -> URL {
        App.configuration.services.etehreumBlockBrowserURL
            .appendingPathComponent("address").appendingPathComponent(address)
    }

    static func exists(_ address: String) -> Bool {
        by(address: address) != nil
    }

    static func create(address: String, name: String, network: Network, selected: Bool = true) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let safe = Safe(context: context)
        safe.address = address
        safe.name = name
        safe.network = network

        if selected {
            safe.select()
        }

        App.shared.coreDataStack.saveContext()
        Tracker.shared.setSafeCount(count)
        App.shared.notificationHandler.safeAdded(address: Address(exactly: address))

        updateCachedNames()
    }
    
    static func edit(address: String, name: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().by(address: address)
        guard let safe = try? context.fetch(fr).first else { return }
        safe.name = name
        App.shared.coreDataStack.saveContext()
        NotificationCenter.default.post(name: .selectedSafeUpdated, object: nil)

        updateCachedNames()
    }

    static func select(address: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().by(address: address)
        guard let safe = try? context.fetch(fr).first else { return }
        safe.select()
    }
    
    static func remove(safe: Safe) {
        let deletedSafeAddress = safe.address
        let context = App.shared.coreDataStack.viewContext

        if let network = safe.network, network.safe?.count == 1 {
            // remove network with associated safe
            Network.remove(network: network)
        } else {
            context.delete(safe)
        }

        if let selection = safe.selection {
            let fr = Safe.fetchRequest().all()
            if let safeToSelect = try? context.fetch(fr).first {
                selection.safe = safeToSelect
            }
        }

        App.shared.coreDataStack.saveContext()
        Tracker.shared.setSafeCount(count)
        NotificationCenter.default.post(name: .selectedSafeChanged, object: nil)

        if let addressString = deletedSafeAddress, let address = Address(addressString) {
            App.shared.notificationHandler.safeRemoved(address: address)
        }

        updateCachedNames()
    }

    static func removeAll() throws {
        Network.removeAll()
    }
}

extension Safe {
    func update(from info: SafeInfoRequest.ResponseType) {
        threshold = info.threshold.value
        ownersInfo = info.owners.map { $0.addressInfo }
        implementationInfo = info.implementation.addressInfo
        version = info.version
        nonce = info.nonce.value
        modulesInfo = info.modules?.map { $0.addressInfo }
        fallbackHandlerInfo = info.fallbackHandler?.addressInfo
    }
}

extension NSFetchRequest where ResultType == Safe {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Safe.additionDate, ascending: true)]
        return self
    }

    func by(address: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address CONTAINS[c] %@", address)
        fetchLimit = 1
        return self
    }

    func by(network: Network) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chain = %@", network)
        return self
    }

    func selected() -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "selection != nil")
        return self
    }
}
