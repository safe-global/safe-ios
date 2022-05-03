//
//  AddKeyAsOwnerController.swift
//  Multisig
//
//  Created by Vitaly on 25.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddKeyAsOwnerController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    private var privateKey: PrivateKey!

    var onSkipped: (() -> Void)?
    var onAdded: (() -> Void)?
    var onReplaced: (() -> Void)?

    convenience init(privateKey: PrivateKey) {
        self.init()
        self.privateKey = privateKey
        let introVC = AddKeyAsOwnerIntroViewController()
        introVC.onAdd = { [unowned self] in
            self.showAddOwnerSettings()
        }
        introVC.onReplace = { [unowned self] in
            self.showSelectOwnerToReplace()
        }
        introVC.onSkip = onSkipped
        ViewControllerFactory.addCloseButton(introVC)
        viewControllers = [introVC]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onSkipped?()
    }

    func showSelectOwnerToReplace() {
        //TODO: navigate to safe owner selection

        guard let safe = try? Safe.getSelected() else { return }
        guard let key = try? KeyInfo.all().first else { return }

        // TODO for now we skip to Review screen
        // TODO select a random owner of the current select safe to be replaced
        let ownerToBeReplaced = try! KeyInfo.keys(addresses: [safe.ownersInfo!.first!.address]).first
        let replaceOwnerReviewVC = ReviewChangeSafeTxViewController(safe: safe, owner: key, oldOwnersCount: safe.ownersInfo?.count ?? 0, oldThreshold: Int(safe.threshold ?? 0), newThreshold: 5, ownerToBeReplaced: ownerToBeReplaced)
        show(replaceOwnerReviewVC, sender: self)
    }

    func showAddOwnerSettings() {
        guard let safe = try? Safe.getSelected() else { return }
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count) + 1
        confirmationsVC.stepNumber = 1
        confirmationsVC.maxSteps = 2
        confirmationsVC.trackingEvent = .addAsOwnerChangeConfirmations
        confirmationsVC.completion = { [weak self] in
            self?.showAddOwnerReview()
        }
        show(confirmationsVC, sender: self)
    }

    func showAddOwnerReview() {
        guard let safe = try? Safe.getSelected() else { return }
        guard let key = try? KeyInfo.all().first else { return }

        let addOwnerReviewVC = ReviewChangeSafeTxViewController(safe: safe, owner: key, oldOwnersCount: safe.ownersInfo?.count ?? 0, oldThreshold: Int(safe.threshold ?? 0), newThreshold: 5)
        show(addOwnerReviewVC, sender: self)
        //TODO: add listeners
    }

    func showAddOwnerSuccess() {
        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It needs to be confirmed and executed first before the owner will be added.",
            primaryAction: "View transaction details",
            secondaryAction: "Done",
            trackingEvent: .addAsOwnerSuccess)
        successVC.onDone = { [unowned self] isPrimaryAction in
            // TODO: open tx details if primary action called - uncomment when we have tx object
            // NotificationCenter.default.post(
            //     name: .initiateTxNotificationReceived,
            //     object: self,
            //     userInfo: isPrimaryAction ? ["transactionDetails": transaction] : [:])
            dismiss(animated: true)
            onAdded?()
        }
        show(successVC, sender: self)
    }
}
