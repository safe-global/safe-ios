//
//  CreatePasscodeController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreatePasscodeController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    convenience init?(completion: @escaping () -> Void) {
        guard !App.shared.auth.isPasscodeSetAndAvailable else {
            return nil
        }
        let createVC = CreatePasscodeViewController(completion)
        createVC.navigationItem.hidesBackButton = true
        createVC.hidesHeadline = false
        ViewControllerFactory.addCloseButton(createVC)
        self.init(rootViewController: createVC)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        guard let passcodeVC = viewControllers.first as? CreatePasscodeViewController else {
            return
        }
        passcodeVC.skip()
    }
}
