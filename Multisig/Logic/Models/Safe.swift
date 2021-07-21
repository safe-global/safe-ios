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
import Version

// "address:chainId" -> name
fileprivate var cachedNames = [String: String]()

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

    enum DomainSeparatorTypeHash {
        static let v1_1_1 = Data(ethHex: "0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749")
        static let v1_3_0 = Data(ethHex: "0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218")
    }

    static func domainData(for safe: AddressString, version: String, chainId: String) -> Data {
        if let v = Version(version), v >= Version("1.3.0")! {
            let chainIdData = UInt256(chainId, radix: 10)!.data32
            return DomainSeparatorTypeHash.v1_3_0 + chainIdData + safe.data32
        } else {
            return DomainSeparatorTypeHash.v1_1_1 + safe.data32
        }
    }

    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Safe.fetchRequest().all())) ?? 0
    }

    static var all: [Safe] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(Safe.fetchRequest().all())) ?? []
    }

    static func by(address: String, chainId: String) -> Safe? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().by(address: address, chainId: chainId)
        return try? context.fetch(fr).first
    }

    static func updateCachedNames() {
        guard let safes = try? Safe.getAll() else { return }

        cachedNames = safes.reduce(into: [String: String]()) { names, safe in
            let chainId = safe.chain != nil ? safe.chain!.id! : "1"
            let key = "\(safe.displayAddress):\(chainId)"
            names[key] = safe.name!
        }
    }

    static func cachedName(by address: AddressString, chainId: String) -> String? {
        let key = "\(address.description):\(chainId)"
        return cachedNames[key]
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

    static func exists(_ address: String, chainId: String) -> Bool {
        by(address: address, chainId: chainId) != nil
    }

    @discardableResult
    static func create(address: String, version: String, name: String, chain: Chain, selected: Bool = true) -> Safe {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let safe = Safe(context: context)
        safe.address = address
        safe.contractVersion = version
        safe.name = name
        safe.chain = chain

        if selected {
            safe.select()
        }

        App.shared.coreDataStack.saveContext()

        Tracker.setSafeCount(count)
        Tracker.trackEvent(.userSafeAdded, parameters: ["chain_id" : chain.id!])

        updateCachedNames()

        return safe
    }

    func update(name: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        self.name = name

        App.shared.coreDataStack.saveContext()
        NotificationCenter.default.post(name: .selectedSafeUpdated, object: nil)

        Safe.updateCachedNames()
    }

    static func select(address: String, chainId: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = Safe.fetchRequest().by(address: address, chainId: chainId)
        guard let safe = try? context.fetch(fr).first else { return }
        safe.select()
    }
    
    static func remove(safe: Safe) {
        let deletedSafeAddress = safe.address
        let context = App.shared.coreDataStack.viewContext

        let chainId = safe.chain!.id!

        if safe.chain!.safe!.count == 1 {
            // remove chain with associated safe
            Chain.remove(chain: safe.chain!)
        } else {
            context.delete(safe)
        }

        if let safe = try? Safe.getAll().first {
            safe.select()
        }

        App.shared.coreDataStack.saveContext()

        Tracker.setSafeCount(count)
        Tracker.trackEvent(.userSafeRemoved, parameters: ["chain_id" : chainId])

        NotificationCenter.default.post(name: .selectedSafeChanged, object: nil)

        if let addressString = deletedSafeAddress, let address = Address(addressString) {
            App.shared.notificationHandler.safeRemoved(address: address, chainId: chainId)
        }

        updateCachedNames()
    }

    static func removeAll() throws {
        Chain.removeAll()
    }
}

extension Safe {
    func update(from info: SafeInfoRequest.ResponseType) {
        DispatchQueue.main.async {
            self.contractVersion = info.version
            App.shared.coreDataStack.saveContext()
        }

        threshold = info.threshold.value
        ownersInfo = info.owners.map { $0.addressInfo }
        implementationInfo = info.implementation.addressInfo
        nonce = info.nonce.value
        modulesInfo = info.modules?.map { $0.addressInfo }
        fallbackHandlerInfo = info.fallbackHandler?.addressInfo
        guardInfo = info.guard?.addressInfo
    }
}

extension NSFetchRequest where ResultType == Safe {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Safe.additionDate, ascending: true)]
        return self
    }

    func by(address: String, chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address == %@ AND chain.id == %@", address, chainId)
        fetchLimit = 1
        return self
    }

    func selected() -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "selection != nil")
        return self
    }
}
