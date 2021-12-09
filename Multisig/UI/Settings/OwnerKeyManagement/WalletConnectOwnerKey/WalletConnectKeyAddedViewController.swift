//
//  WalletConnectKeyAdded.swift
//  Multisig
//
//  Created by Moaaz on 11/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class WalletConnectKeyAddedViewController: AccountActionCompletedViewController {
    private var addKeyController: AddDelegateKeyController!

    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        titleText = "Connect WalletConnect"
        headerText = "Owner Key added"

        assert(accountName != nil)
        assert(accountAddress != nil)

        descriptionText = "\(accountName ?? "Key") can't receive push notificaitons without your confirmation.\n\nYou can change this at any time in App Settings - Owner Keys - Key Details."

        primaryActionName = "Confirm to receive push notifications"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addDelegateKeyWalletConnect)
    }

    override func primaryAction(_ sender: Any) {
        // Start Add Delegate flow with the selected account address
        Tracker.trackEvent(.addDelegateKeyStarted)
        addKeyController = AddDelegateKeyController(ownerAddress: accountAddress, completion: completion)
        addKeyController.presenter = self
        addKeyController.start()
    }

    override func secondaryAction(_ sender: Any) {
        // doing nothing because user skipped
        Tracker.trackEvent(.addDelegateKeySkipped)
        completion()
    }
}
