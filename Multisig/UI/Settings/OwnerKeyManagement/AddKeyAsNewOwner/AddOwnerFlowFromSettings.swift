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
    var newAddress: Address?
    var newAddressName: String?

    var addOwnerFlowFromSettingsFactory: AddOwnerFlowFromSettingsFactory {
        factory as! AddOwnerFlowFromSettingsFactory
    }
    init(safe: Safe, factory: AddOwnerFlowFromSettingsFactory = .init(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        super.init(newOwner: nil, safe: safe, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func start() {
        enterAddressViewController()
    }

    func enterAddressViewController() {
        let viewController = addOwnerFlowFromSettingsFactory.enterOwnerAddress { [unowned self] address, resolvedName  in
            newAddress = address

            if let resolvedName = resolvedName {
                self.newAddressName = resolvedName
                confirmations()
            } else {
                enterOwnerNameViewController()
            }
        }

        show(viewController)
    }

    func enterOwnerNameViewController() {
        assert(newAddress != nil)
        let viewController = addOwnerFlowFromSettingsFactory.enterOwnerName(safe: safe, address: newAddress!) { [unowned self] name in
            newAddressName = name
            confirmations()
        }

        show(viewController)
    }

    func confirmations() {
        confirmations(stepNumber: 2, maxSteps: 3)
    }
}

class AddOwnerFlowFromSettingsFactory: AddOwnerFlowFactory {
    func enterOwnerAddress(completion: @escaping (Address, String?) -> Void) -> EnterOwnerAddressViewController {
        let enterOwnerAddressVC = EnterOwnerAddressViewController()
        enterOwnerAddressVC.stepNumber = 1
        enterOwnerAddressVC.maxSteps = 3
        enterOwnerAddressVC.trackingEvent = .addOwnerSelectAddress

        enterOwnerAddressVC.completion = completion

        return enterOwnerAddressVC
    }

    func enterOwnerName(safe: Safe, address: Address, completion: @escaping (String) -> Void) -> EnterOwnerNameViewController {
        let enterNameVC = EnterOwnerNameViewController()
        enterNameVC.address = address
        enterNameVC.prefix = safe.chain!.shortName
        enterNameVC.completion = completion
        return enterNameVC
    }
}
