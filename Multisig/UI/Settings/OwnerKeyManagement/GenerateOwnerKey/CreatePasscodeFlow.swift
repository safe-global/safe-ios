//
//  CreatePasscodeFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class CreatePasscodeFlow: UIFlow {
    var factory: PasscodeFlowFactory

    init(factory: PasscodeFlowFactory = PasscodeFlowFactory(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(navigationController: navigationController, completion: completion)
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
}

