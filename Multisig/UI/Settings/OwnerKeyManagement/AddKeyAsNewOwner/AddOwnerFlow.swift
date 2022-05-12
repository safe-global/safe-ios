//
//  AddOwnerFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddOwnerFlow: UIFlow {
    var factory: AddOwnerFlowFactory
    var newOwner: AddressInfo
    var safe: Safe
    var newConfirmations: Int?
    var addOwnerTransactionDetails: SCGModels.TransactionDetails?

    init(newOwner: AddressInfo, safe: Safe, factory: AddOwnerFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.newOwner = newOwner
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        confirmations()
    }

    func confirmations() {
        let confirmationsVC = factory.confirmations(
            safe: safe
        ) { [unowned self] newConfirmations in
            self.newConfirmations = newConfirmations
            review()
        }
        show(confirmationsVC)
    }

    func review() {
        assert(newConfirmations != nil)
        let reviewVC = factory.review(
            safe: safe,
            key: newOwner,
            newThreshold: newConfirmations!) { [unowned self] txDetails in
                addOwnerTransactionDetails = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(addOwnerTransactionDetails != nil)
        let successVC = factory.success { [unowned self] showTxDetails in
            if showTxDetails {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: ["transactionDetails": addOwnerTransactionDetails!])
            }
            stop(success: !showTxDetails)
        }
        show(successVC)
    }
}

class AddOwnerFlowFactory {
    func confirmations(safe: Safe, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count) + 1
        confirmationsVC.stepNumber = 1
        confirmationsVC.maxSteps = 2
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations
        confirmationsVC.completion = completion
        confirmationsVC.showPromptLabel = true
        return confirmationsVC
    }

    func review(safe: Safe, key: AddressInfo, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewAddOwnerTxViewController {
        let addOwnerReviewVC = ReviewAddOwnerTxViewController(
            safe: safe,
            owner: key,
            oldOwnersCount: safe.ownersInfo?.count ?? 0,
            oldThreshold: Int(safe.threshold ?? 0),
            newThreshold: newThreshold)
        addOwnerReviewVC.stepNumber = 2
        addOwnerReviewVC.maxSteps = 2
        addOwnerReviewVC.onSuccess = completion
        return addOwnerReviewVC
    }

    func success(completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be added.",
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: .addAsOwnerSuccess)
        successVC.onDone = completion
        return successVC
    }
}

class AddOwnerFlowFromSettingsFactory: AddOwnerFlowFactory {

    override func confirmations(safe: Safe, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count) + 1
        confirmationsVC.stepNumber = 2
        confirmationsVC.maxSteps = 3
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations
        confirmationsVC.completion = completion
        confirmationsVC.showPromptLabel = true
        return confirmationsVC
    }

    override func review(safe: Safe, key: AddressInfo, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewAddOwnerTxViewController {
        let addOwnerReviewVC = ReviewAddOwnerTxViewController(
            safe: safe,
            owner: key,
            oldOwnersCount: safe.ownersInfo?.count ?? 0,
            oldThreshold: Int(safe.threshold ?? 0),
            newThreshold: newThreshold)
        addOwnerReviewVC.stepNumber = 3
        addOwnerReviewVC.maxSteps = 3
        addOwnerReviewVC.onSuccess = completion
        return addOwnerReviewVC
    }

    override func success(completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be added.",
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: .addAsOwnerSuccess)
        successVC.onDone = completion
        return successVC
    }
}
