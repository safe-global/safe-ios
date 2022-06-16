//
//  ReplaceOwnerFromInviteFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/16/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
class ReplaceOwnerFromInviteFlow: ReplaceOwnerFlow {
    var newOwnerName: String?

    override func start() {
        assert(newOwner != nil)

        newOwnerName = AddressBookEntry.cachedName(by: AddressString(newOwner!), chainId: safe.chain!.id!)

        let vc = factory.enterOwnerName(safe: safe,
                               address: newOwner!,
                               name: newOwnerName,
                               stepNumber: 1,
                               maxSteps: 3,
                               title: "Replace owner",
                               trackingEvent: .replaceOwnerNewOwnerName) { [unowned self] name in
            newOwnerName = name
            pickOwnerToReplace()
        }

        show(vc)
    }


    override func success() {
        assert(transaction != nil)
        AddressBookEntry.addOrUpdate(newOwner!.checksummed, chain: safe.chain!, name: newOwnerName!)
        let successVC = factory.success (bodyText: "It needs to be confirmed and executed first before the owner will be replaced.",
                                         trackingEvent: .replaceOwnerSuccess){ [unowned self] showTxDetails in
            if showTxDetails {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: ["transactionDetails": transaction!])
            }

            stop(success: !showTxDetails)
        }
        show(successVC)
    }
}
