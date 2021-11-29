//
//  LedgerKeyAddedViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyAddedViewController: AccountActionCompletedViewController {
    private var addKeyController: AddDelegateKeyController!

    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        titleText = "Connect Ledger Nano X"
        headerText = "Owner Key added"

        assert(accountName != nil)
        assert(accountAddress != nil)

        descriptionText = "\(accountName ?? "Key") can't receive push notificaitons without your confirmation.\n\nYou can change this at any time in App Settings - Owner Keys - Key Details."

        primaryActionName = "Confirm to receive push notifications"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func primaryAction(_ sender: Any) {
        // Start Add Delegate flow with the selected account address
        #warning("TODO: tracking?")
        addKeyController = AddDelegateKeyController(ownerAddress: accountAddress, completion: completion)
        addKeyController.presenter = self
        addKeyController.start()
    }

    override func secondaryAction(_ sender: Any) {
        // doing nothing because user skipped
        #warning("TODO: tracking?")
        completion()
    }
}
