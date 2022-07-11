//
//  ReplaceOwnerFromSettingsFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for replacing existing owner of a safe with a new address.
///
/// Expects that the owner to replace is known.
///
/// Screen sequence:
///
/// 1. Enter Address
/// 1.1. If name is unknown, then Enter Name
/// 2. Review (in superclass)
/// 3. Success
class ReplaceOwnerFromSettingsFlow: ReplaceOwnerFlow {
    var newAddressName: String?

    init(ownerToReplace: Address, prevOwner: Address?, safe: Safe, completion: @escaping (_ success: Bool) -> Void) {
        super.init(newOwner: nil, safe: safe, completion: completion)
        self.ownerToReplace = ownerToReplace
        self.prevOwner = prevOwner
    }

    override func start() {
        enterAddressViewController()
    }

    func enterAddressViewController() {
        let viewController = replaceOwnerFactory.enterOwnerAddress(
            safe: safe,
            stepNumber: 1,
            maxSteps: 3,
            title: "Replace owner",
            trackingEvent: .replaceOwnerSelectNew
        ) { [unowned self] address, resolvedName  in
            newOwner = address

            if let resolvedName = resolvedName {
                self.newAddressName = resolvedName
                review()
            } else {
                enterOwnerNameViewController()
            }
        }

        show(viewController)
    }

    func enterOwnerNameViewController() {
        assert(newOwner != nil)
        let viewController = replaceOwnerFactory.enterOwnerName(
            safe: safe,
            address: newOwner!,
            stepNumber: 1,
            maxSteps: 3,
            title: "Replace owner",
            trackingEvent: .replaceOwnerNewOwnerName
        ) { [unowned self] name in
            newAddressName = name
            review()
        }

        show(viewController)
    }

    override func review() {
        assert(ownerToReplace != nil)
        assert(newOwner != nil)
        let reviewVC = replaceOwnerFactory.review(
                step: 2,
                maxSteps: 2,
                safe: safe,
                newOwner: newOwner!,
                ownerToReplace: ownerToReplace!,
                previousOwner: prevOwner,
                newAddressName: newAddressName
        ) { [unowned self] txDetails in
            transaction = txDetails
            success()
        }
        show(reviewVC)
    }

    override func success() {
        assert(transaction != nil)
        AddressBookEntry.addOrUpdate(newOwner!.checksummed, chain: safe.chain!, name: newAddressName!)
        super.success()
    }
}
