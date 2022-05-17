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

    init(newOwner: AddressInfo, safe: Safe, factory: AddOwnerFlowFactory = .init(), navigationController: UINavigationController, presenter: UIViewController? = nil, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.newOwner = newOwner
        super.init(navigationController: navigationController, presenter: presenter, completion: completion)
    }

    override func start() {
        confirmations()
        super.start()
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
        return confirmations(
            safe: safe,
            minConfirmations: 1,
            maxConfirmations: max(1, (safe.ownersInfo ?? []).count) + 1,
            stepNumber: 1,
            maxSteps: 2,
            trackingEvent: .addAsOwnerChangeConfirmations,
            completion: completion)
    }

    fileprivate func confirmations(
        safe: Safe,
        minConfirmations: Int,
        maxConfirmations: Int,
        stepNumber: Int,
        maxSteps: Int,
        trackingEvent: TrackingEvent,
        completion: @escaping (_ newConfirmations: Int) -> Void
    ) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 1)
        confirmationsVC.minConfirmations = minConfirmations
        confirmationsVC.maxConfirmations = maxConfirmations
        confirmationsVC.stepNumber = stepNumber
        confirmationsVC.maxSteps = maxSteps
        confirmationsVC.trackingEvent = trackingEvent
        confirmationsVC.promptText = "You’re about to add an owner. Would you like to change the required confirmations?"
        confirmationsVC.completion = completion
        return confirmationsVC
    }

    func review(safe: Safe, key: AddressInfo, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewAddOwnerTxViewController {
        return review(
            safe: safe,
            key: key,
            newThreshold: newThreshold,
            stepNumber: 2,
            maxSteps: 2,
            completion: completion
        )
    }

    fileprivate func review(
        safe: Safe,
        key: AddressInfo,
        newThreshold: Int,
        stepNumber: Int,
        maxSteps: Int,
        completion: @escaping (SCGModels.TransactionDetails) -> Void
    ) -> ReviewAddOwnerTxViewController {
        let addOwnerReviewVC = ReviewAddOwnerTxViewController(
            safe: safe,
            owner: key,
            oldOwnersCount: safe.ownersInfo?.count ?? 0,
            oldThreshold: Int(safe.threshold ?? 0),
            newThreshold: newThreshold)
        addOwnerReviewVC.stepNumber = stepNumber
        addOwnerReviewVC.maxSteps = maxSteps
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
        return confirmations(
            safe: safe,
            minConfirmations: 1,
            maxConfirmations: max(1, (safe.ownersInfo ?? []).count) + 1,
            stepNumber: 2,
            maxSteps: 3,
            trackingEvent: .addAsOwnerChangeConfirmations,
            completion: completion)
    }

    override func review(safe: Safe, key: AddressInfo, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewAddOwnerTxViewController {
        return review(
            safe: safe,
            key: key,
            newThreshold: newThreshold,
            stepNumber: 3,
            maxSteps: 3,
            completion: completion
        )
    }
}
