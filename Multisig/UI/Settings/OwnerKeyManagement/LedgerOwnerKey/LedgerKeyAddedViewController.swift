//
//  LedgerKeyAddedViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyAddedViewController: AccountActionCompletedViewController {
    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        titleText = "Connect Ledger Nano X"
        headerText = "Owner Key added"

        accountName = "<KEY>"
        accountAddress = .zero

        descriptionText = "\(accountName ?? "Key") can't receive push notificaitons without your confirmation.\n\nConfirming will let our servers authorize this device to receive push notifications by creating device-only delegate key. You can change this at any time in App Settings - Owner Keys - Key Details.\n\nWould you like to create a delegate key to receive push notifications?"

        primaryActionName = "Confirm to receive push notifications"
        secondaryActionName = "I don't want push notifications for this key"

        super.viewDidLoad()
    }

    override func primaryAction(_ sender: Any) {
        // Add Delegate
        // when added - call completion
        completion()
    }

    override func secondaryAction(_ sender: Any) {
        // Do nothing, call completion
        completion()
    }
}
