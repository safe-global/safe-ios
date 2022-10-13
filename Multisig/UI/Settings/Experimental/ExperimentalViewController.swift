//
//  ExperimentalViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 21.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExperimentalViewController: UITableViewController {
    
    // Add experimental toggles here
//    @UserDefault(key: "io.gnosis.multisig.experimental.<toggleName>")
//    var <toggleName>Enabled: Bool? {
//        didSet {
//            tableView.reloadData()
//            // track if necessary
//            Tracker.set<toggleName>Enabled(<toggleName>Enabled ?? false)
//            NotificationCenter.default.post(name: .updatedExperemental, object: nil)
//        }
//    }

    enum Row: Int, CaseIterable {
       // Add rows for experimental settigns
       // Replace toggleName with real toggles
        case toggleName
    }

    private lazy var rows: [Row] = {
        var rows: [Row] = []
//        if App.configuration.toggles.<toggleName>Enabled {
//            rows += [.<toggleName>, .<toggleName>Description]
//        }
        return rows
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Experimental"

        tableView.backgroundColor = .backgroundSecondary
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WalletConnectDescription")

        tableView.backgroundColor = .backgroundPrimary
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.experimental)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        switch rows[indexPath.row] {
//        case .<toggleName>:
//            let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
//            cell.setText("toggle name")
//            cell.setOn(desktopPairingEnabled!, animated: false)
//            return cell
//
//        case .<toggleName>Description:
//            return descriptionCell(
//                "toggle description",
//                indexPath: indexPath
//            )
//        }
//    }

    private func descriptionCell(_ text: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(UITableViewCell.self, reuseID: "WalletConnectDescription", for: indexPath)
        cell.textLabel?.setStyle(.body)
        cell.backgroundColor = .backgroundPrimary
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
//        case .<toggleName>:
//            <toggleName>Enabled!.toggle()

        default:
            break
        }
    }
}
