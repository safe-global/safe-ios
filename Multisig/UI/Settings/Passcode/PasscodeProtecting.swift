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
    func authenticate(biometry: Bool, options: PasscodeOptions, completion: @escaping (_ success: Bool) -> Void)
}

extension PasscodeProtecting where Self: UIViewController {
    func authenticate(biometry: Bool = true, options: PasscodeOptions = [], completion: @escaping (_ success: Bool) -> Void) {
        if App.shared.auth.isPasscodeSetAndAvailable && (options.isEmpty || !AppSettings.passcodeOptions.intersection(options).isEmpty) {
            let passcodeVC = EnterPasscodeViewController()
            passcodeVC.usesBiometry = biometry
            passcodeVC.passcodeCompletion = { [weak self] result in
                self?.dismiss(animated: true) {
                    switch result {
                    case .close:
                        completion(false)
                    case.success(_) :
                        completion(true)
                    }
                }
            }

            let nav = UINavigationController(rootViewController: passcodeVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            completion(true)
        }
    }
}
