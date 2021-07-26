//
//  MultisigNotification+ContentProvider.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import SwiftCryptoTokenFormatter

protocol NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void)
}

extension MultisigNotification: NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        switch self {
        case let .incomingNativeCoin(n):
            n.loadContent(completion: completion)
        case let .incomingToken(n):
            n.loadContent(completion: completion)
        case let .executedMultisigTransaction(n):
            n.loadContent(completion: completion)
        case let .newConfirmation(n):
            n.loadContent(completion: completion)
        case let .confirmationRequest(n):
            n.loadContent(completion: completion)
        case .unknown:
            completion(nil)
        }
    }
}

extension SafeNotification {
    func loadSafe(completion: @escaping (Safe?, NSManagedObjectContext) -> Void) {
        NotificationService.coreData.persistentContainer.performBackgroundTask { context in
            completion(safe(context: context, address: address, chainId: chainId), context)
        }
    }

    func safe(context: NSManagedObjectContext, address: AddressString, chainId: UInt256String) -> Safe? {
        do {
            let fr = Safe.fetchRequest().by(address: address.description, chainId: chainId.description)
            let safe = try context.fetch(fr).first
            return safe
        } catch {
            print("Failed to fetch safe: \(error)")
            return nil
        }
    }

    func keyInfo(context: NSManagedObjectContext, address: AddressString) -> KeyInfo? {
        do {
            let fr = KeyInfo.fetchRequest().by(address: address.address)
            let info = try context.fetch(fr).first
            return info
        } catch {
            print("Failed to fetch key info: \(error)")
            return nil
        }
    }

}

extension MultisigNotification.IncomingNativeCoin: NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        loadSafe { safeOrNil, _ in
            guard
                let safe = safeOrNil,
                let chain = safe.chain,
                let chainName = chain.name,
                let nativeCoin = chain.nativeCurrency,
                let symbol = nativeCoin.symbol
            else {
                completion((
                    title: "Incoming token (Chain Id \(chainId))",
                    body: "\(address.address.truncatedInMiddle): \(value) received"
                ))
                return
            }
            let safeName = safe.name ?? address.address.truncatedInMiddle
            let formatter = TokenFormatter()
            let amount = formatter.string(
                from: BigDecimal(Int256(value.value), Int(nativeCoin.decimals)),
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")

            let title = "Incoming \(symbol) (\(chainName))"
            let body = "\(safeName): \(amount) \(symbol) received"
            completion((title, body))
        }
    }
}

extension MultisigNotification.IncomingToken: NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        loadSafe { safeOrNil, _ in
            guard
                let safe = safeOrNil,
                let chain = safe.chain,
                let chainName = chain.name
            else {
                completion((
                    title: "Incoming token (Chain Id \(chainId))",
                    body: "\(address.address.truncatedInMiddle): tokens received"
                ))
                return
            }
            let safeName = safe.name ?? address.address.truncatedInMiddle

            let title = "Incoming token (\(chainName))"
            var body = "\(safeName): "
            switch tokenType {
            case .erc20: body += "ERC20 tokens received"
            case .erc721: body += "ERC721 token received"
            case .unknown: body += "tokens received"
            }
            completion((title, body))
        }
    }
}

extension MultisigNotification.ExecutedMultisigTransaction: NotificationContentProvider {
    var localizedStatus: String {
        failed.value ? "failed" : "successful"
    }

    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        loadSafe { safeOrNil, _ in
            guard
                let safe = safeOrNil,
                let chain = safe.chain,
                let chainName = chain.name
            else {
                completion((
                    title: "Transaction \(localizedStatus) (Chain Id \(chainId))",
                    body: "\(address.address.truncatedInMiddle): Transaction \(localizedStatus)"
                ))
                return
            }
            let safeName = safe.name ?? address.address.truncatedInMiddle

            let title = "Transaction \(localizedStatus) (\(chainName))"
            let body = "\(safeName): Transaction \(localizedStatus)"
            completion((title, body))
        }
    }
}

extension MultisigNotification.ConfirmationRequest: NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        loadSafe { safeOrNil, _ in
            guard
                let safe = safeOrNil,
                let chain = safe.chain,
                let chainName = chain.name
            else {
                completion((
                    title: "Confirmation required (Chain Id \(chainId))",
                    body: "\(address.address.truncatedInMiddle): A transaction requires your confirmation!"
                ))
                return
            }
            let safeName = safe.name ?? address.address.truncatedInMiddle

            let title = "Confirmation required (\(chainName))"
            let body = "\(safeName): A transaction requires your confirmation!"
            completion((title, body))
        }
    }
}

extension MultisigNotification.NewConfirmation: NotificationContentProvider {
    func loadContent(completion: @escaping ((title: String, body: String)?) -> Void) {
        loadSafe { safeOrNil, context in
            guard
                let safe = safeOrNil,
                let chain = safe.chain,
                let chainName = chain.name
            else {
                completion((
                    title: "Transaction confirmed (Chain Id \(chainId))",
                    body: "\(address.address.truncatedInMiddle): Owner \(owner.address.truncatedInMiddle) confirmed transaction"
                ))
                return
            }
            let safeName = safe.name ?? address.address.truncatedInMiddle
            let ownerInfo = keyInfo(context: context, address: owner)
            let ownerName = ownerInfo?.name ?? owner.address.truncatedInMiddle
            let title = "Transaction confirmed (\(chainName))"
            let body = "\(safeName): Owner \(ownerName) confirmed transaction"
            completion((title, body))
        }
    }
}
