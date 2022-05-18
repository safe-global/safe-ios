//
//  RemoveOwnerFlow.swift
//  Multisig
//
//  Created by Moaaz on 5/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class RemoveOwnerFlow: UIFlow {
    var factory: RemoveOwnerFlowFactory
    var safe: Safe
    var ownerToRemove: Address?
    var prevOwner: Address?
    var newConfirmations: Int?
    var removeOwnerTransactionDetails: SCGModels.TransactionDetails?

    internal init(owner: Address, prevOwner: Address?, safe: Safe, factory: RemoveOwnerFlowFactory = .init(), navigationController: UINavigationController,  presenter: UIViewController? = nil, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.ownerToRemove = owner
        self.prevOwner = prevOwner
        super.init(navigationController: navigationController, presenter: presenter, completion: completion)
    }

    override func start() {
        confirmations()
        super.start()
    }

    func confirmations() {
        let confirmationsVC = factory.confirmations(
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

        let reviewVC = factory.review(
            step: 2,
            maxSteps: 2,
            safe: safe,
            owner: ownerToRemove!,
            prevOwner: prevOwner, newThreshold: newConfirmations!) { [unowned self] txDetails in
                removeOwnerTransactionDetails = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(removeOwnerTransactionDetails != nil)
        let successVC = factory.success { [unowned self] showTxDetails in
            if showTxDetails {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: ["transactionDetails": removeOwnerTransactionDetails!])
            }
            stop(success: !showTxDetails)
        }
        show(successVC)
    }
}

class RemoveOwnerFlowFactory {
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

    func success(completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be removed.",
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: .removeOwnerSuccess)
        successVC.onDone = completion
        return successVC
    }
}
