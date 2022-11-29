//
//  AddOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerKeyViewController: UITableViewController {

    private(set) var completion: () -> Void = {}
    private var showsCloseButton: Bool = true
    private var keyTypes: [(type: KeyType, title: String, subtitle: String)] = [
        (.deviceImported, "Import existing owner key", "Import an existing key or a seed phrase"),
        (.deviceGenerated, "Create new owner key", "Create a new key that you can use as an owner of your Safe"),
        (.ledgerNanoX, "Connect Ledger Nano X", "Add a key from your hardware wallet"),
        (.keystone, "Connect Keystone", "Connect your key via QR code")
    ]

    convenience init(showsCloseButton: Bool = true, completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
        self.showsCloseButton = showsCloseButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Owner Key"

        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(CloseModal.closeModal))
        }

        tableView.registerCell(AddOwnerKeyCell.self)
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .backgroundPrimary

        keyTypes.append(
            (.walletConnect, "Connect key", "Connect an existing key from another wallet using WalletConnect")
        )
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
        switch keyTypes[indexPath.row].type {
        case .deviceGenerated:
            cell.set(iconName: KeyType.deviceGenerated.imageName)
        case .deviceImported:
            cell.set(iconName: KeyType.deviceImported.imageName)
        case .ledgerNanoX:
            cell.set(iconName: KeyType.ledgerNanoX.imageName)
        case .walletConnect:
            cell.set(iconName: KeyType.walletConnect.imageName)
        case .keystone:
            cell.set(iconName: "ico-add-keystone")

        }
        return cell
    }

    var importKeyFlow: ImportKeyFlow!
    var generateKeyFlow: GenerateKeyFlow!
    var connectKeystoneFlow: ConnectKeystoneFlow!
    var walletConnectKeyFlow: WalletConnectKeyFlow!
    var ledgerKeyFlow: LedgerKeyFlow!

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller: UIViewController

        switch keyTypes[indexPath.row].type {
        case .deviceImported:
            importKeyFlow = ImportKeyFlow { [unowned self] _ in
                importKeyFlow = nil
                completion()
            }
            push(flow: importKeyFlow)
            return

        case .deviceGenerated:
            generateKeyFlow = GenerateKeyFlow { [unowned self] _ in
                generateKeyFlow = nil
                completion()
            }
            push(flow: generateKeyFlow)
            return

        case .walletConnect:
            walletConnectKeyFlow = WalletConnectKeyFlow { [unowned self] _ in
                walletConnectKeyFlow = nil
                completion()
            }
            push(flow: walletConnectKeyFlow)
            return

        case .ledgerNanoX:
            ledgerKeyFlow = LedgerKeyFlow { [unowned self] _ in
                ledgerKeyFlow = nil
                completion()
            }
            push(flow: ledgerKeyFlow)
            return
            
        case .keystone:
            connectKeystoneFlow = ConnectKeystoneFlow { [unowned self] _ in
                connectKeystoneFlow = nil
                completion()
            }
            push(flow: connectKeystoneFlow)
            return
        }
        show(controller, sender: self)
    }
}
