//
//  PasscodeProtecting.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 27.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol PasscodeProtecting {
    func authenticate(biometry: Bool, options: PasscodeOptions, completion: @escaping (_ success: Bool, _ reset: Bool) -> Void)
}

extension PasscodeProtecting where Self: UIViewController {
    func authenticate(biometry: Bool = true, options: PasscodeOptions = [], completion: @escaping (_ success: Bool, _ reset: Bool) -> Void) {
        if App.shared.auth.isPasscodeSetAndAvailable && (options.isEmpty || !AppSettings.passcodeOptions.intersection(options).isEmpty) {
            let passcodeVC = EnterPasscodeViewController()
            passcodeVC.usesBiometry = biometry
            passcodeVC.passcodeCompletion = { [weak self] success, reset in
                self?.dismiss(animated: true) {
                    completion(success, reset)
                }
            }

            let nav = UINavigationController(rootViewController: passcodeVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            completion(true, false)
        }
    }
}
