//
//  KeyAddedViewController.swift
//  Multisig
//
//  Created by Mouaz on 11/1/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
class KeyAddedViewController: AccountActionCompletedViewController {
    private var addKeyController: DelegateKeyController!
    private var keyType: KeyType!

    convenience init(address: Address, name: String, keyType: KeyType, completion: @escaping () -> Void) {
        self.init(namedClass: AccountActionCompletedViewController.self)
        self.keyType = keyType
        self.accountAddress = address
        self.accountName = name
        self.completion = completion
    }

    override func viewDidLoad() {
        titleText = keyType.titleText
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
        Tracker.trackEvent(keyType.trackingEvent)
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
        }
    }

    var trackingEvent: TrackingEvent {
        switch self {
        case .ledgerNanoX: return .addDelegateKeyLedger
        case .deviceImported: return .addDelegateKeyImported
        case .deviceGenerated: return .addDelegateKeyGenerated
        case .keystone: return .addDelegateKeyKeystone
        case .walletConnect: return .addDelegateKeyWalletConnect
        }
    }
}
