//
//  ActivateBiometryAlertController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ActivateBiometryAlertController: UIAlertController {

    var completion: () -> Void = { }

    convenience init(completion: @escaping () -> Void) {
        self.init(
            title: "Activate Biometry?",
            message: "Would you like to enable login with biometrics?",
            preferredStyle: .alert)
        self.completion = completion

        addAction(UIAlertAction(title: "Enable", style: .default, handler: { [unowned self] _ in
            enable()
        }))

        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] _ in
            cancel()
        }))
    }

    func enable() {
        App.shared.auth.activateBiometrics { [unowned self] _ in
            // in any resulting case, finish.
            completion()
        }
    }

    func cancel() {
        completion()
    }
}

