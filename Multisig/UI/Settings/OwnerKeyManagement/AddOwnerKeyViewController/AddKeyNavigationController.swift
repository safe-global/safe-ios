//
//  AddKeyNavigationController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddKeyNavigationController: UINavigationController, UINavigationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let selectWalletVC = viewController as? SelectWalletViewController {
            selectWalletVC.cancelExistingConnection()
        }
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if let selectWalletVC = viewControllers.compactMap({ $0 as? SelectWalletViewController }).first {
            selectWalletVC.cancelExistingConnection()
        } else if let vc = viewControllers.compactMap({ $0 as? AddOwnerKeyViewController }).first {
            vc.completion()
        }
    }
}
