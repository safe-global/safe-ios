//
//  ExperimentalViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 21.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExperimentalViewController: UITableViewController {
    @UserDefault(key: "io.gnosis.multisig.experimental.walletConnect")
    var walletConnectEnabled: Bool? {
        didSet {
            tableView.reloadData()
            NotificationCenter.default.post(name: .updatedExperemental, object: nil)
        }
    }

    @UserDefault(key: "io.gnosis.multisig.experimental.walletConnectOwnerKey")
    var walletConnectOwnerKeyEnabled: Bool? {
        didSet {
            tableView.reloadData()
            NotificationCenter.default.post(name: .updatedExperemental, object: nil)
        }
    }

    enum Row: Int, CaseIterable {
        case walletConnect
        case walletConnectDescription
        case walletConnectOwnerKey
        case walletConnectOwnerKeyDescription
    }

    private var rows: [Row] = [
        .walletConnect, .walletConnectDescription, .walletConnectOwnerKey, .walletConnectOwnerKeyDescription
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Experimental"

        tableView.backgroundColor = .secondaryBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WalletConnectDescription")

        if walletConnectEnabled == nil {
            walletConnectEnabled = false
        }

        if walletConnectOwnerKeyEnabled == nil {
            walletConnectOwnerKeyEnabled = false
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .walletConnect:
            let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
            cell.setText("Enable WalletConnect for Dapps")
            cell.setOn(walletConnectEnabled!, animated: false)
            return cell

        case .walletConnectDescription:
            return descriptionCell(
                "Try out interacting with Dapps via WalletConnect.",
                indexPath: indexPath
            )

        case .walletConnectOwnerKey:
            let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
            cell.setText("Enable WalletConnect for owner keys")
            cell.setOn(walletConnectOwnerKeyEnabled!, animated: false)
            return cell

        case .walletConnectOwnerKeyDescription:
            return descriptionCell(
                "Try out connecting owner key and executing transactions via WalletConnect.",
                indexPath: indexPath
            )
        }
    }

    private func descriptionCell(_ text: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(UITableViewCell.self, reuseID: "WalletConnectDescription", for: indexPath)
        cell.textLabel?.setStyle(.secondary)
        cell.backgroundColor = .primaryBackground
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .walletConnect:
            walletConnectEnabled!.toggle()

        case .walletConnectOwnerKey:
            walletConnectOwnerKeyEnabled!.toggle()

        default:
            break
        }
    }
}
