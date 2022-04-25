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
        introVC.onSkip = { [unowned self] in
            self.onSkipped?()
        }
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
        //TODO: navigate to add owner & confirmations adjustment screen 
    }
}
