//
//  ReplaceOwnerController.swift
//  Multisig
//
//  Created by Vitaly on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

//TODO: adjust
class ReplaceOwnerController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    private var keyInfo: KeyInfo!

    var onSkipped: (() -> Void)?
    var onSuccess: (() -> Void)?

    convenience init(keyInfo: KeyInfo) {
        self.init()
        self.keyInfo = keyInfo

        assert((try? Safe.getSelected() ?? nil) != nil)

        viewControllers = [createKeyPickerContoller()]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onSkipped?()
    }

    func createKeyPickerContoller() -> UIViewController {
        let ownerPickerVC = SafeOwnerPickerViewController()
        //TODO: set fields
        return ownerPickerVC
    }

    func createConfirmationsVC() -> UIViewController? {
        guard let safe = try? Safe.getSelected() else { return nil }
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count)
        confirmationsVC.stepNumber = 2
        confirmationsVC.maxSteps = 2
        //TODO: adjust tracking
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations
        confirmationsVC.completion = { [weak self] confirmations in
            self?.showReplaceOwnerReview(newThreshold: confirmations)
        }

        return confirmationsVC
    }

    func showReplaceOwnerReview(newThreshold: Int) {
        guard let safe = try? Safe.getSelected() else { return }
        guard let key = keyInfo else { return }
//TODO: wire replace owner review screen
//        let replaceOwnerReviewVC = ...
//        replaceOwnerReviewVC.onSuccess = { [weak self] transaction in
//            self?.showReplaceOwnerSuccess(transaction: transaction)
//        }
//        show(replaceOwnerReviewVC, sender: self)
    }

    func showReplaceOwnerSuccess(transaction: SCGModels.TransactionDetails) {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be replaced.",
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: .addAsOwnerSuccess)
        successVC.onDone = { [unowned self] isPrimaryAction in
            if isPrimaryAction {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: isPrimaryAction ? ["transactionDetails": transaction] : [:])
            }
            dismiss(animated: true)
            onSuccess?()
        }
        show(successVC, sender: self)
    }
}
