//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ChangeConfirmationsFlow: UIFlow {
    var factory: ChangeConfirmationsFlowFactory
    var safe: Safe
    var newConfirmations: Int?
    var changeConfirmationsTransactionDetails: SCGModels.TransactionDetails?
    weak var presenter: UIViewController!

    init(safe: Safe, presenter: UIViewController, factory: ChangeConfirmationsFlowFactory = .init(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.safe = safe
        self.presenter = presenter
        let navigationController = CancellableNavigationController()
        super.init(navigationController: navigationController, completion: completion)
        navigationController.onCancel = { [unowned self] in
            stop(success: false)
        }
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
            changeConfirmationsTransactionDetails = txDetails
            success()
        }
        show(reviewVC)
    }

    func success() {
        assert(changeConfirmationsTransactionDetails != nil)
        let successVC = factory.success { [unowned self] showTxDetails in
            if showTxDetails {
                NotificationCenter.default.post(
                        name: .initiateTxNotificationReceived,
                        object: self,
                        userInfo: ["transactionDetails": changeConfirmationsTransactionDetails!])
            }
            stop(success: !showTxDetails)
        }
        show(successVC)
    }

    override func start() {
        confirmations()
        // guaranteed to exist at this point
        let rootVC = navigationController.viewControllers.first!
        ViewControllerFactory.addCloseButton(rootVC)
        presenter.present(navigationController, animated: true)
    }

    override func stop(success: Bool) {
        presenter.dismiss(animated: true) { [unowned self] in
            completion(success)
        }
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
        confirmationsVC.trackingEvent = .changeConfirmations
        confirmationsVC.completion = completion
        confirmationsVC.showPromptLabel = false
        return confirmationsVC
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
