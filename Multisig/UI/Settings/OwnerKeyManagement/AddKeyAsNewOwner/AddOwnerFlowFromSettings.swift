//
//  AddOwnerFlowFromSettingsFactory.swift
//  Multisig
//
//  Created by Moaaz on 5/17/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddOwnerFlowFromSettings: AddOwnerFlow {
    init(newOwner: AddressInfo, safe: Safe, factory: AddOwnerFlowFromSettingsFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        super.init(newOwner: newOwner, safe: safe, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func start() {
        confirmations(stepNumber: 2, maxSteps: 3)
    }
}

class AddOwnerFlowFromSettingsFactory: AddOwnerFlowFactory {

    func enterOwnerAddress(completion: @escaping () -> Void) -> EnterOwnerAddressViewController {
        let enterOwnerAddressVC = EnterOwnerAddressViewController()
        enterOwnerAddressVC.stepNumber = 1
        enterOwnerAddressVC.maxSteps = 3
        enterOwnerAddressVC.trackingEvent = .addOwnerSelectAddress

        enterOwnerAddressVC.completion = completion

        return enterOwnerAddressVC
    }
}
