//
//  ReplaceOwnerFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for replacing an owner of a safe with another address.
///
/// Expects that a new owner address is known.
///
/// This class is also a base for another flow where the owner to replace is known
/// but the new owner is unknown.
///
/// Screen sequence:
/// 1. Pick Owner to Replace
/// 2. Review
/// 3. Success
class ReplaceOwnerFlow: SafeSettingsChangeFlow {
    var newOwner: Address?
    var ownerToReplace: Address?
    var prevOwner: Address?

    var replaceOwnerFactory: ReplaceOwnerFlowFactory {
        factory as! ReplaceOwnerFlowFactory
    }

    internal init(newOwner: Address?, safe: Safe, completion: @escaping (_ success: Bool) -> Void) {
        self.newOwner = newOwner
        super.init(safe: safe, factory: ReplaceOwnerFlowFactory(), completion: completion)
    }

    override func start() {
        pickOwnerToReplace()
    }

    func pickOwnerToReplace() {
        let pickOwnerToReplaceVC = replaceOwnerFactory.pickOwnerToReplace() { [unowned self] previousOwner, ownerToReplace in
            self.ownerToReplace = ownerToReplace
            self.prevOwner = previousOwner
            review()
        }
        show(pickOwnerToReplaceVC)
    }

    func review() {
        assert(ownerToReplace != nil)
        assert(newOwner != nil)
        let reviewVC = replaceOwnerFactory.review(
            step: 2,
            maxSteps: 2,
            safe: safe,
            newOwner: newOwner!,
            ownerToReplace: ownerToReplace!,
            previousOwner: prevOwner) { [unowned self] txDetails in
                transaction = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(transaction != nil)
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

class ReplaceOwnerFlowFactory: SafeSettingsFlowFactory {

    func pickOwnerToReplace(onContinue: @escaping (_ previousOwner: Address?, _ ownerToReplace: Address) -> Void) -> SafeOwnerPickerViewController {
        let safeOwnerPickerVC = SafeOwnerPickerViewController()
        safeOwnerPickerVC.onContinue = onContinue
        return safeOwnerPickerVC
    }

    func review(
        step: Int,
        maxSteps: Int,
        safe: Safe,
        newOwner: Address,
        ownerToReplace: Address,
        previousOwner: Address?,
        newAddressName: String? = nil,
        completion: @escaping (SCGModels.TransactionDetails) -> Void
    ) -> ReviewReplaceOwnerTxViewController {

        let addOwnerReviewVC = ReviewReplaceOwnerTxViewController(
            safe: safe,
            owner: newOwner,
            ownerToBeReplaced: ownerToReplace,
            previousOwner: previousOwner,
            ownersCount: safe.ownersInfo?.count ?? 0,
            threshold: Int(safe.threshold ?? 0),
            newAddressName: newAddressName
        )
        addOwnerReviewVC.stepNumber = step
        addOwnerReviewVC.maxSteps = maxSteps
        addOwnerReviewVC.onSuccess = completion
        return addOwnerReviewVC
    }
}
