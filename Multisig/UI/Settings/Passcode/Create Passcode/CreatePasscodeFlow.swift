//
//  CreatePasscodeFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for creating a passcode
///
/// Screen sequence:
///
/// 1. Create Passcode
/// 1.1. Nothing, if the passcode already created.
class CreatePasscodeFlow: UIFlow {
    var factory: PasscodeFlowFactory

    init(factory: PasscodeFlowFactory = PasscodeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        create()
    }

    func create() {
        guard !App.shared.auth.isPasscodeSetAndAvailable else {
            stop(success: false)
            return
        }
        let createVC = factory.create { [unowned self] in
            stop(success: true)
        }
        show(createVC)
    }
}

class PasscodeFlowFactory {
    func create(completion: @escaping () -> Void) -> CreatePasscodeViewController {
        let createVC = CreatePasscodeViewController(completion)
        createVC.navigationItem.hidesBackButton = true
        return createVC
    }

    func enter(biometry: Bool = true, options: PasscodeOptions = [], reset: @escaping () -> Void = { }, completion: @escaping (_ success: Bool) -> Void) -> EnterPasscodeViewController? {
        guard App.shared.auth.isPasscodeSetAndAvailable && (options.isEmpty || !AppSettings.passcodeOptions.intersection(options).isEmpty) else {
            return nil
        }
        let passcodeVC = EnterPasscodeViewController()
        passcodeVC.usesBiometry = biometry
        passcodeVC.passcodeCompletion = { isSuccess, isReset in
            if isReset {
                reset()
            } else {
                completion(isSuccess)
            }
        }
        return passcodeVC
    }
}
