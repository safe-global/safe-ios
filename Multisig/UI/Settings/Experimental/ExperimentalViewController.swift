//
//  ExperimentalViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 21.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExperimentalViewController: UITableViewController {
    @UserDefault(key: "io.gnosis.multisig.experimental.desktopPairing")
    var desktopPairingEnabled: Bool? {
        didSet {
            tableView.reloadData()
            Tracker.setDesktopPairingEnabled(desktopPairingEnabled ?? false)
            NotificationCenter.default.post(name: .updatedExperemental, object: nil)
        }
    }

    enum Row: Int, CaseIterable {
        case desktopPairing
        case desktopPairingDescription
    }

    private lazy var rows: [Row] = {
        var rows: [Row] = []
        if App.configuration.toggles.desktopPairingExperimentalEnabled {
            rows += [.desktopPairing, .desktopPairingDescription]
        }
        return rows
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Experimental"

        tableView.backgroundColor = .secondaryBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WalletConnectDescription")

        tableView.backgroundColor = .primaryBackground

        if desktopPairingEnabled == nil {
            desktopPairingEnabled = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.experimental)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .desktopPairing:
            let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
            cell.setText("Enable Desktop Pairing")
            cell.setOn(desktopPairingEnabled!, animated: false)
            return cell

        case .desktopPairingDescription:
            return descriptionCell(
                "It allows connecting your owner keys to the desktop app.",
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
        case .desktopPairing:
            desktopPairingEnabled!.toggle()

        default:
            break
        }
    }
}
