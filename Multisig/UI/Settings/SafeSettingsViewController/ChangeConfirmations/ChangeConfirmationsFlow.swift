//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ChangeConfirmationsFlow: SafeSettingsChangeFlow {
    var newConfirmations: Int?
    var changeConfirmationsTransactionDetails: SCGModels.TransactionDetails?

    var changeConfirmationsFlowFactory: ChangeConfirmationsFlowFactory {
        factory as! ChangeConfirmationsFlowFactory
    }

    init(safe: Safe, presenter: UIViewController, factory: ChangeConfirmationsFlowFactory = .init(), completion: @escaping (_ success: Bool) -> Void) {
        self.presenter = presenter
        let navigationController = CancellableNavigationController()
        super.init(safe: safe, factory: factory, navigationController: navigationController, completion: completion)
        navigationController.onCancel = { [unowned self] in
            stop(success: false)
        }
    }

    func confirmations() {
        let confirmationsVC = changeConfirmationsFlowFactory.confirmations(
            safe: safe,
            stepNumber: 1,
            maxSteps: 2
        ) { [unowned self] newConfirmations in
            self.newConfirmations = newConfirmations
            review()
        }
        show(confirmationsVC)
    }

    func review() {
        assert(newConfirmations != nil)
        let reviewVC = changeConfirmationsFlowFactory.review(
                step: 2,
                maxSteps: 2,
                safe: safe,
                newThreshold: newConfirmations!) { [unowned self] txDetails in
            transaction = txDetails
            success()
        }
        show(reviewVC)
    }

    func success() {
        assert(transaction != nil)
        let successVC = factory.success (bodyText: "The confirmations will be changed once this transaction is executed.",
                                         trackingEvent: .changeConfirmationsSuccess){ [unowned self] showTxDetails in
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

    override func start() {
        confirmations()
        super.start()
    }
}

class ChangeConfirmationsFlowFactory: SafeSettingsFlowFactory {
    func confirmations(safe: Safe, stepNumber: Int, maxSteps: Int, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        confirmations(
            confirmations: Int(safe.threshold ?? 1),
            minConfirmations: 1,
            maxConfirmations: max(1, (safe.ownersInfo ?? []).count) + 1,
            stepNumber: stepNumber,
            maxSteps: maxSteps,
            promptText: "",
            trackingEvent: .changeConfirmations,
            completion: completion)
    }

    func review(step: Int, maxSteps: Int, safe: Safe, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewChangeConfirmationsTxViewController {
        let changeConfirmationsReviewVC = ReviewChangeConfirmationsTxViewController(
                safe: safe,
                ownersCount: safe.ownersInfo?.count ?? 0,
                oldThreshold: Int(safe.threshold ?? 0),
                newThreshold: newThreshold)
        changeConfirmationsReviewVC.stepNumber = step
        changeConfirmationsReviewVC.maxSteps = maxSteps
        changeConfirmationsReviewVC.onSuccess = completion
        return changeConfirmationsReviewVC
    }

    func success(completion: @escaping (_ showTxDetails: Bool) -> Void) -> SuccessViewController {
        let successVC = SuccessViewController(
                titleText: "Your transaction is submitted!",
                bodyText: "It needs to be confirmed and executed first before the owner will be added.",
                primaryAction: "View transaction details",
                secondaryAction: "Done",
                trackingEvent: .changeConfirmationsSuccess)
        successVC.onDone = completion
        return successVC
    }
}
