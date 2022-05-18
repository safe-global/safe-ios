//
//  AddOwnerFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddOwnerFlow: SafeSettingsChangeFlow {
    var newOwner: AddressInfo

    var newConfirmations: Int?

    var addOwnerFactory: AddOwnerFlowFactory {
        factory as! AddOwnerFlowFactory
    }

    init(newOwner: AddressInfo, safe: Safe, factory: AddOwnerFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.newOwner = newOwner
        super.init(safe: safe, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func start() {
        confirmations(stepNumber: 1, maxSteps: 2)
    }

    func confirmations(stepNumber: Int, maxSteps: Int) {
        let confirmationsVC = addOwnerFactory.confirmations(safe: safe,
                                                    stepNumber: stepNumber,
                                                    maxSteps: maxSteps) { [unowned self] newConfirmations in
            self.newConfirmations = newConfirmations
            review(stepNumber: stepNumber + 1, maxSteps: maxSteps)
        }
        show(confirmationsVC)
    }

    func review(stepNumber: Int, maxSteps: Int) {
        assert(newConfirmations != nil)
        let reviewVC = addOwnerFactory.review(
            safe: safe,
            key: newOwner,
            newThreshold: newConfirmations!,
            stepNumber: stepNumber,
            maxSteps: maxSteps) { [unowned self] txDetails in
                transaction = txDetails
                success()
            }
        show(reviewVC)
    }

    func success() {
        assert(transaction != nil)
        let successVC = factory.success (bodyText: "It needs to be confirmed and executed first before the owner will be added.",
                                         trackingEvent: .addAsOwnerSuccess) { [unowned self] showTxDetails in
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

class AddOwnerFlowFactory: FlowFactory {
    func confirmations(safe: Safe, stepNumber: Int, maxSteps: Int, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        confirmations(
            confirmations: Int(safe.threshold ?? 1),
            minConfirmations: 1,
            maxConfirmations: max(1, (safe.ownersInfo ?? []).count) + 1,
            stepNumber: stepNumber,
            maxSteps: maxSteps,
            promptText: "You’re about to add an owner. Would you like to change the required confirmations?",
            trackingEvent: .addAsOwnerChangeConfirmations,
            completion: completion)
    }

    func review(
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
}


