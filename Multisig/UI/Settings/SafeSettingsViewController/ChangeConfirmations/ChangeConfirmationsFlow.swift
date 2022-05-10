//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ChangeConfirmationsFlow: UIFlow {
    var factory: ChangeConfirmationsFlowFactory
    //var newOwner: KeyInfo
    var safe: Safe
    var newConfirmations: Int?
    var addOwnerTransactionDetails: SCGModels.TransactionDetails?

    init(safe: Safe, factory: ChangeConfirmationsFlowFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        confirmations()
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
        assert(newConfirmations != nil)
        let reviewVC = factory.review(
                step: 2,
                maxSteps: 2,
                safe: safe,
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

class ChangeConfirmationsFlowFactory {
    func confirmations(step: Int, maxSteps: Int, safe: Safe, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count)
        confirmationsVC.stepNumber = step
        confirmationsVC.maxSteps = maxSteps
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations //TODO change when available
        confirmationsVC.completion = completion
        return confirmationsVC
    }

    func review(step: Int, maxSteps: Int, safe: Safe, newThreshold: Int, completion: @escaping (SCGModels.TransactionDetails) -> Void) -> ReviewChangeConfirmationsTxViewController {
        let addOwnerReviewVC = ReviewChangeConfirmationsTxViewController (
                safe: safe,
                ownersCount: safe.ownersInfo?.count ?? 0,
                oldThreshold: Int(safe.threshold ?? 0),
                newThreshold: newThreshold)
        addOwnerReviewVC.stepNumber = step
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
                trackingEvent: .addAsOwnerSuccess) //TODO change when available
        successVC.onDone = completion
        return successVC
    }
}
