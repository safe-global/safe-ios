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
    var newOwner: KeyInfo
    var replaceOwnerTransactionDetails: SCGModels.TransactionDetails?

    internal init(newOwner: KeyInfo, safe: Safe, factory: ReplaceOwnerFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.newOwner = newOwner
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        pickOwnerToReplace()
    }

    func pickOwnerToReplace() {
        let pickOwnerToReplaceVC = factory.pickOwnerToReplace() { [unowned self] previousOwner, ownerToReplace in
            //TODO review
        }
        show(pickOwnerToReplaceVC)
    }
}

class ReplaceOwnerFlowFactory {

    func pickOwnerToReplace(onContinue: @escaping (_ previousOwner: Address, _ ownerToReplace: Address) -> Void) -> SafeOwnerPickerViewController {
        let safeOwnerPickerVC = SafeOwnerPickerViewController()
        safeOwnerPickerVC.onContinue = onContinue
        return safeOwnerPickerVC
    }

    func review(step: Int, maxSteps: Int, safe: Safe, key: KeyInfo, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewChangeSafeTxViewController {
        let addOwnerReviewVC = ReviewChangeSafeTxViewController(
            safe: safe,
            owner: key,
            oldOwnersCount: safe.ownersInfo?.count ?? 0,
            oldThreshold: Int(safe.threshold ?? 0),
            newThreshold: newThreshold)
        addOwnerReviewVC.stepNumber = step
        addOwnerReviewVC.maxSteps = maxSteps
        addOwnerReviewVC.onSuccess = completion
        return addOwnerReviewVC
    }
}
