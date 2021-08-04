//
//  AddOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerKeyViewController: UITableViewController {
    private var completion: () -> Void = {}

    private var keyTypes: [(type: KeyType, title: String, subtitle: String)] = [
        (.deviceImported, "Import Existing Key", "Imort an existing key or seed phrase"),
        (.deviceGenerated, "Create New Key", "Create a new key that you can use as owner of your Gnosis Safe"),
        (.ledgerNanoX, "Connect Ledger Wallet", "Add a key from your hardware wallet")
    ]

    convenience init(completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Owner Key"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(CloseModal.closeModal))

        tableView.registerCell(AddOwnerKeyCell.self)
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .primaryBackground

        if App.configuration.toggles.walletConnectOwnerKeyEnabled {
            keyTypes.append(
                (.walletConnect, "Connect Key", "Connect an existing key from another wallet using WalletConnect")
            )
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerKeysOptions)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keyTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyType = keyTypes[indexPath.row]
        let cell = tableView.dequeueCell(AddOwnerKeyCell.self)
        cell.set(title: keyType.title)
        cell.set(subtitle: keyType.subtitle)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller: UIViewController

        switch keyTypes[indexPath.row].type {
        case .deviceImported:
            controller = OnboardingImportOwnerKeyViewController(completion: completion)

        case .deviceGenerated:
            controller = OnboardingGenerateKeyViewController(completion: completion)

        case .walletConnect:
            controller = OnboardingConnectOwnerKeyViewController(completion: completion)

        #warning("TODO: finish implementation")
        case .ledgerNanoX:
            controller = SelectLedgerDeviceViewController()
        }
        show(controller, sender: self)
    }
}
