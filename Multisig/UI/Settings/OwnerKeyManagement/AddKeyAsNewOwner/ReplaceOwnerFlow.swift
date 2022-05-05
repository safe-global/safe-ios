//
//  ReplaceOwnerFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ReplaceOwnerFlow: UIFlow {

    var factory: ReplaceOwnerFlowFactory
    var safe: Safe
    var oldOwner: Address
    var newOwner: KeyInfo
    var replaceOwnerTransactionDetails: SCGModels.TransactionDetails?

    internal init(factory: ReplaceOwnerFlowFactory = .init(), safe: Safe, oldOwner: Address, newOwner: KeyInfo, navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.oldOwner = oldOwner
        self.newOwner = newOwner
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        pickOwnerToReplace()
    }

    func pickOwnerToReplace() {

    }
}


class ReplaceOwnerFlowFactory {
}
