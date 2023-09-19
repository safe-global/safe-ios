//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for changing required number of transaction confirmations in the safe.
///
/// Screen sequence:
///
/// 1. Edit Confirmations
/// 2. Review
/// 3. Success
class ChangeConfirmationsFlow: SafeSettingsChangeFlow {
    var newConfirmations: Int?
    var changeConfirmationsTransactionDetails: SCGModels.TransactionDetails?

    var changeConfirmationsFlowFactory: ChangeConfirmationsFlowFactory {
        factory as! ChangeConfirmationsFlowFactory
    }

    init?(safe: Safe?, completion: @escaping (_ success: Bool) -> Void) {
        guard Self.canChangeConfirmations(safe: safe) else { return nil }
        super.init(safe: safe!, factory: ChangeConfirmationsFlowFactory(), completion: completion)
    }

    override func start() {
        confirmations()
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

    // true iff can execute transactions (not read-only) and max threshold is at least 2 confirmations
    // otherwise, the threshold is capped at 1 and it won't make sense to change it
    static func canChangeConfirmations(safe: Safe?) -> Bool {
        if let safe = safe, !safe.isReadOnly,
           let maxThreshold = safe.ownersInfo?.count, maxThreshold >= 2 {
            return true
        } else {
            return false
        }
    }
}

class ChangeConfirmationsFlowFactory: SafeSettingsFlowFactory {
    func confirmations(safe: Safe, stepNumber: Int, maxSteps: Int, completion: @escaping (_ newConfirmations: Int) -> Void) -> EditConfirmationsViewController {
        confirmations(
            confirmations: Int(safe.threshold ?? 1),
            minConfirmations: 1,
            maxConfirmations: max(1, (safe.ownersInfo ?? []).count),
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
