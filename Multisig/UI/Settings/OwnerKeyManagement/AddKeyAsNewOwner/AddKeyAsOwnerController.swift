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
    }

    func showAddOwnerSettings() {
        guard let safe = try? Safe.getSelected() else { return }
        let confirmationsVC = EditConfirmationsViewController()
        confirmationsVC.confirmations = Int(safe.threshold ?? 0)
        confirmationsVC.minConfirmations = 1
        confirmationsVC.maxConfirmations = max(1, (safe.ownersInfo ?? []).count) + 1
        confirmationsVC.stepNumber = 1
        confirmationsVC.maxSteps = 2
        confirmationsVC.completion = onAdded
        show(confirmationsVC, sender: self)
    }
}
