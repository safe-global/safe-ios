//
//  KeyNotificationViewController.swift
//  Multisig
//
//  Created by Mouaz on 11/1/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
class KeyNotificationViewController: AccountActionCompletedViewController {
    private var addKeyController: DelegateKeyController!
    private var type: KeyType!

    convenience init(address: Address, name: String, type: KeyType, completion: @escaping () -> Void) {
        self.init(namedClass: AccountActionCompletedViewController.self)
        self.type = type
        self.accountAddress = address
        self.accountName = name
        self.completion = completion
    }

    override func viewDidLoad() {
        titleText = type.titleText
        headerText = "Owner Key added"

        assert(accountName != nil)
        assert(accountAddress != nil)

        descriptionText = "\(accountName ?? "Key") can't receive push notifications without your confirmation.\n\nYou can change this at any time in App Settings - Owner Keys - Key Details."

        primaryActionName = "Confirm to receive push notifications"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screen_add_delegate, parameters: ["key_type" : type.name])
    }

    override func primaryAction(_ sender: Any) {
        // Start Add Delegate flow with the selected account address
        Tracker.trackEvent(.addDelegateKeyStarted)
        do {
            addKeyController = try DelegateKeyController(ownerAddress: accountAddress, completion: completion)
            addKeyController.presenter = self
            addKeyController.createDelegate()
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    override func secondaryAction(_ sender: Any) {
        // doing nothing because user skipped
        Tracker.trackEvent(.addDelegateKeySkipped)
        completion()
    }
}

fileprivate extension KeyType {
    var titleText: String {
        switch self {
        case .ledgerNanoX: return "Connect Ledger Nano X"
        case .deviceImported: return "Import Owner Key"
        case .deviceGenerated: return "Generate Owner Key"
        case .keystone: return "Connect Keystone"
        case .walletConnect: return "Connect WalletConnect"
        case .web3AuthApple: return "Login via Web2"
        case .web3AuthGoogle: return "Login via Web2"
        }
    }
}
