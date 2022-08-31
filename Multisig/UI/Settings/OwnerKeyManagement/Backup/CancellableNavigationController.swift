//
//  CancellableNavigationController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class CancellableNavigationController: UINavigationController, UIAdaptivePresentationControllerDelegate {

    var dismissableOnSwipe: Bool = true
    var onCancel: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationController?.delegate = self
        // disable swipe down gesture
        isModalInPresentation = !dismissableOnSwipe
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard dismissableOnSwipe else { return }
        onCancel?()
    }
}
