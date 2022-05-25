//
//  ReplaceOwnerFromSettingsFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

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
}
