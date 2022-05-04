//
//  AddKeyAsOwnerController.swift
//  Multisig
//
//  Created by Vitaly on 25.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    private var keyInfo: KeyInfo?

    var onSkipped: (() -> Void)?
    var onSuccess: (() -> Void)?

    convenience init(keyInfo: KeyInfo? = nil) {
        self.init()
        self.keyInfo = keyInfo

        assert((try? Safe.getSelected() ?? nil) != nil)

        if let _ = keyInfo {
            viewControllers = [createConfirmationsVC()!]
        } else {
            viewControllers = [createKeyPickerContoller()]
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onSkipped?()
    }

    func createKeyPickerContoller() -> UIViewController {
        UIViewController()
    }

    func createConfirmationsVC() -> UIViewController? {
        guard let safe = try? Safe.getSelected() else { return nil }
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count) + 1
        confirmationsVC.stepNumber = 1
        confirmationsVC.maxSteps = 2
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations
        confirmationsVC.completion = { [weak self] confirmations in
            self?.showAddOwnerReview(newThreshold: confirmations)
        }

        return confirmationsVC
    }

    func showAddOwnerReview(newThreshold: Int) {
        guard let safe = try? Safe.getSelected() else { return }
        guard let key = keyInfo else { return }

        let addOwnerReviewVC = ReviewChangeSafeTxViewController(safe: safe,
                                                                owner: key,
                                                                oldOwnersCount: safe.ownersInfo?.count ?? 0,
                                                                oldThreshold: Int(safe.threshold ?? 0),
                                                                newThreshold: newThreshold)
        show(addOwnerReviewVC, sender: self)
        addOwnerReviewVC.onSuccess = { [weak self] transaction in
            self?.showAddOwnerSuccess(transaction: transaction)
        }
    }

    func showAddOwnerSuccess(transaction: SCGModels.TransactionDetails) {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be added.",
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

    func showSelectOwnerToReplace() {
        //TODO: navigate to safe owner selection

        guard let safe = try? Safe.getSelected() else { return }
        guard let key = try? KeyInfo.all().first else { return }

        // TODO for now we skip to Review screen
        // TODO select a random owner of the current select safe to be replaced
        let addresses =  safe.ownersInfo!.compactMap { info in
            info.address
        }
        do {
            let ownerToBeReplaced = try KeyInfo.keys(addresses: addresses).first
            let replaceOwnerReviewVC = ReviewReplaceOwnerTxViewController(safe: safe,
                    owner: key,
                    oldOwnersCount: safe.ownersInfo?.count ?? 0,
                    oldThreshold: Int(safe.threshold ?? 0),
                    ownerToBeReplaced: ownerToBeReplaced!)
            show(replaceOwnerReviewVC, sender: self)
        } catch {
            LogService.shared.info("[REPLACE_OWNER] failed")
        }

    }
}
