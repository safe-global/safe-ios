//
//  RemoveOwnerFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Flow for removing owner from a safe.
///
/// Expects that an owner to be removed is known in advance.
///
/// Screen sequence:
///
/// 1. Edit Confirmations
/// 2. Review
/// 3. Success
class RemoveOwnerFlow: SafeSettingsChangeFlow {
    var ownerToRemove: Address?
    var prevOwner: Address?
    var newConfirmations: Int?
    
    var removeOwnerFactory: RemoveOwnerFlowFactory! {
        factory as? RemoveOwnerFlowFactory
    }

    internal init(
        owner: Address,
        prevOwner: Address?,
        safe: Safe,
        completion: @escaping (_ success: Bool) -> Void
    ) {
        self.ownerToRemove = owner
        self.prevOwner = prevOwner
        super.init(safe: safe, factory: RemoveOwnerFlowFactory(), completion: completion)
    }

    override func start() {
        confirmations()
    }

    func confirmations() {
        let confirmationsVC = removeOwnerFactory.confirmations(
            step: 1,
            maxSteps: 2,
            safe: safe
        ) { [unowned self] newConfirmations in
            self.newConfirmations = newConfirmations
            review()
        }
        show(confirmationsVC)
    }

    func review() {
        assert(ownerToRemove != nil)
        assert(newConfirmations != nil)

        let reviewVC = removeOwnerFactory.review(
            step: 2,
            maxSteps: 2,
            safe: safe,
            owner: ownerToRemove!,
            prevOwner: prevOwner, newThreshold: newConfirmations!) { [unowned self] txDetails in
                transaction = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(transaction != nil)
        let successVC = factory.success (bodyText: "It needs to be confirmed and executed first before the owner will be removed.",
                                         trackingEvent: .removeOwnerSuccess){ [unowned self] showTxDetails in
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

class RemoveOwnerFlowFactory: SafeSettingsFlowFactory {
    func confirmations(step: Int, maxSteps: Int, safe: Safe, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 1)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count - 1)
        confirmationsVC.stepNumber = step
        confirmationsVC.maxSteps = maxSteps
        confirmationsVC.trackingEvent = .removeOwnerChangePolicy
        confirmationsVC.promptText = "You’re about to remove an owner. Would you like to change the required confirmations?"
        confirmationsVC.titleText = "Remove owner"
        confirmationsVC.completion = completion
        return confirmationsVC
    }

    func review(step: Int, maxSteps: Int, safe: Safe, owner: Address, prevOwner: Address?, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewRemoveOwnerViewController {
        let removeOwnerVC = ReviewRemoveOwnerViewController(
            safe: safe,
            owner: owner,
            previousOwner: prevOwner,
            oldOwnersCount: safe.ownersInfo?.count ?? 0,
            oldThreshold: Int(safe.threshold ?? 0),
            newThreshold: newThreshold)
        removeOwnerVC.stepNumber = step
        removeOwnerVC.maxSteps = maxSteps
        removeOwnerVC.onSuccess = completion
        return removeOwnerVC
    }
}
