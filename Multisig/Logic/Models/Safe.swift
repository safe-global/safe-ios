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

extension Safe {

    var isSelected: Bool { selection != nil }

    var hasAddress: Bool { address?.isEmpty == false }

    var displayAddress: String { address! }

    var addressValue: Address { Address(address!)! }

    var browserURL: URL { chain!.browserURL(address: displayAddress) }

    var displayENSName: String { ensName ?? "" }

    var safeStatus: SafeStatus {
        get { SafeStatus(rawValue: status) ?? .deployed }
        set { status = newValue.rawValue }
    }

    var isReadOnly: Bool {
        guard let owners = ownersInfo else { return false }
        if let keys = try? KeyInfo.keys(addresses: owners.map(\.address)), !keys.isEmpty {
            return false
        } else {
            return true
        }
    }

    var security: SafeSecurityStatus {
        if securityHasBackup && securityHasEnoughOwners && securityHasRecommendedThreshold {
            return .high
        } else {
            return .medium
        }
    }
    
    // has back up is false iff there are generated keys that need backup
    var securityHasBackup: Bool {
        if let ownersInfo = ownersInfo, let keyInfos = try? KeyInfo.keys(addresses: ownersInfo.map(\.address)),
           keyInfos.contains(where: { $0.needsBackup }) {
            return false
        } else {
            return true
        }
    }
    
    var securityHasEnoughOwners: Bool {
        if let ownersInfo = ownersInfo, ownersInfo.count > 1 {
            return true
        } else {
            return false
        }
    }
    
    var securityHasRecommendedThreshold: Bool {
        if let threshold = threshold,
           let ownersInfo = ownersInfo,
           threshold > 1 && ownersInfo.count > 2 {
            return true
        } else {
            return false
        }
    }

    var walletConnectSessiontopics: [String] {
        guard let topics = sessionTopics else { return [] }
        return topics.components(separatedBy: " ")
    }

    // Demo address
    static let demoAddress = "0xfF501B324DC6d78dC9F983f140B9211c3EdB4dc7"

    // this value is for contract versions 1.0.0 and 1.1.1 (probably for later versions as well)
    static let DefaultEIP712SafeAppTxTypeHash =
        Data(ethHex: "0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8")

    enum DomainSeparatorTypeHash {
        static let v1_1_1 = Data(ethHex: "0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749")
        static let v1_3_0 = Data(ethHex: "0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218")
    }

    static func domainData(for safe: AddressString, version: Version, chainId: String) -> Data {
        if version >= Version("1.3.0")! {
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

    /// Exclude Demo Safe from counting.
    /// It is acceptable that we will not count a real owner of this Safe.
    static var countExcludingDemo: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: Safe.fetchRequest().allExcludingDemo())) ?? 0
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

    static func by(topic: String) -> Safe? {
        dispatchPrecondition(condition: .onQueue(.main))
        return Safe.all.first {$0.walletConnectSessiontopics.contains(topic)}
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

    static func cachedName(by address: String, chainId: String) -> String? {
        let key = "\(address):\(chainId)"
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

    static func exists(_ address: String, chainId: String) -> Bool {
        by(address: address, chainId: chainId) != nil
    }

    @discardableResult
    static func create(address: String, version: String, name: String, chain: Chain, selected: Bool = true, status: SafeStatus = .deployed) -> Safe {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let safe = Safe(context: context)
        safe.address = address
        safe.contractVersion = version
        safe.name = name
        safe.chain = chain
        safe.safeStatus = status

        if selected {
            safe.select()
        }

        App.shared.coreDataStack.saveContext()

        Tracker.setNumSafesUserProperty(countExcludingDemo)
        Tracker.trackEvent(.userSafeAdded, parameters: ["chain_id" : chain.id!])

        updateCachedNames()

        return safe
    }

    func update(name: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        self.name = name

        App.shared.coreDataStack.saveContext()
        NotificationCenter.default.post(name: .selectedSafeUpdated, object: self)

        Safe.updateCachedNames()
    }

    func addSession(topic: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        var topics = walletConnectSessiontopics
        if topics.contains(topic) { return }
        topics.append(topic)
        sessionTopics = topics.joined(separator: " ")
        App.shared.coreDataStack.saveContext()
    }

    static func removeSession(topic: String) {
        Safe.all.forEach{
            let topics = $0.walletConnectSessiontopics
            if topics.contains(topic) {
                $0.sessionTopics = topics.filter { $0 != topic }.joined(separator: " ")
            }
        }

        App.shared.coreDataStack.saveContext()
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


        if let deletedSafeAddress = deletedSafeAddress {
            // delete related EthTransaction's
            let txs = CDEthTransaction.by(safeAddresses: [deletedSafeAddress], chainId: chainId)
            for tx in txs {
                context.delete(tx)
            }

            // delete stored SafeCreationCall's
            let calls = SafeCreationCall.by(safe: safe)
            for call in calls {
                context.delete(call)
            }
        }

        context.delete(safe)

        if let safe = try? Safe.getAll().first {
            safe.select()
        }

        App.shared.coreDataStack.saveContext()

        Tracker.setNumSafesUserProperty(countExcludingDemo)
        Tracker.trackEvent(.userSafeRemoved, parameters: ["chain_id" : chainId])

        NotificationCenter.default.post(name: .selectedSafeChanged, object: nil)

        if let addressString = deletedSafeAddress, let address = Address(addressString) {
            App.shared.notificationHandler.safeRemoved(address: address, chainId: chainId)
        }

        updateCachedNames()
    }

    static func removeAll() throws {
        for safe in all {
            remove(safe: safe)
        }
        
        NotificationCenter.default.post(name: .selectedSafeChanged, object: nil)
    }
}

extension Safe {
    func update(from info: SafeInfoRequest.ResponseType) {
        threshold = info.threshold.value
        ownersInfo = info.owners.map { $0.addressInfo }
        implementationInfo = info.implementation.addressInfo
        implementationVersionState = ImplementationVersionState(info.implementationVersionState)
        nonce = info.nonce.value
        modulesInfo = info.modules?.map { $0.addressInfo }
        fallbackHandlerInfo = info.fallbackHandler?.addressInfo
        guardInfo = info.guard?.addressInfo
        version = info.version
        DispatchQueue.main.async {
            self.contractVersion = info.version
            App.shared.coreDataStack.saveContext()
            NotificationCenter.default.post(name: .selectedSafeUpdated, object: self)
        }
    }
}

extension NSFetchRequest where ResultType == Safe {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Safe.additionDate, ascending: true)]
        return self
    }

    func allExcludingDemo() -> Self {
        predicate = NSPredicate(format: "%K != %@", "address", Safe.demoAddress)
        return self
    }

    func selected() -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "selection != nil")
        return self
    }
}

extension ImplementationVersionState {
    init(_ implementationVersionState: SCGModels.ImplementationVersionState) {
        switch implementationVersionState {
        case .unknown: self = .unknown
        case .upToDate: self = .upToDate
        case .upgradeAvailable: self = .upgradeAvailable
        }
    }
}

enum SafeStatus: Int16 {
    case deployed = 0
    case deploying = 1
    case deploymentFailed = 2
    case indexing = 3
}

enum SafeSecurityStatus: Int16 {
    case medium = 0
    case high = 1

    var color: UIColor {
        switch self {
        case .medium:
            return .warning
        case .high:
            return .success
        }
    }
}
