//
//  PasscodeSettingsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PasscodeSettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Passcode"
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsAppPasscode)
    }

    enum Row: Int, CaseIterable {
        case usePasscode
        case changePasscode
        case helpText
    }

    private var rows: [Row] = []

    private var isPasscodeSet: Bool {
        App.shared.auth.isPasscodeSet
    }

    private func reloadData() {
        rows = isPasscodeSet ? [.usePasscode, .changePasscode, .helpText] :
            [.usePasscode, .helpText]
        tableView.reloadData()
    }

    private func createPasscode() {
        let vc = CreatePasscodeViewController { [unowned self] in
            reloadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    private func deletePasscode() {
        let vc = EnterPasscodeViewController()
        let nav = UINavigationController(rootViewController: vc)

        vc.completion = { [weak nav, unowned self] success in
            if success {
                do {
                    try App.shared.auth.deletePasscode()
                    App.shared.snackbar.show(message: "Passcode disabled")
                } catch {
                    let uiError = GSError.error(
                        description: "Failed to delete passcode",
                        error: GSError.GenericPasscodeError(reason: error.localizedDescription))
                    App.shared.snackbar.show(error: uiError)
                }
            }
            reloadData()
            nav?.dismiss(animated: true, completion: nil)
        }

        present(nav, animated: true, completion: nil)
    }

    private func changePasscode() {
        let vc = EnterPasscodeViewController()
        vc.navigationItemTitle = "Change Passcode"
        vc.screenTrackingEvent = .changePasscode
        let nav = UINavigationController(rootViewController: vc)

        vc.completion = { [weak nav, unowned self] success in
            if success {
                let changeVC = ChangePasscodeEnterNewViewController { [weak nav, unowned self] in
                    reloadData()
                    nav?.dismiss(animated: true, completion: nil)
                }
                nav?.pushViewController(changeVC, animated: true)
            } else {
                reloadData()
                nav?.dismiss(animated: true, completion: nil)
            }
        }

        present(nav, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .usePasscode:
            let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
            cell.setText("Use passcode")
            cell.setOn(App.shared.auth.isPasscodeSet, animated: false)
            return cell

        case .changePasscode:
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle("Change passcode")
            return cell

        case .helpText:
            let cell = tableView.dequeueCell(UITableViewCell.self, reuseID: "HelpCell", for: indexPath)
            cell.textLabel?.setStyle(.secondary)
            cell.backgroundColor = .primaryBackground
            cell.textLabel?.text = "The passcode is needed to sign transactions."
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .usePasscode:
            if isPasscodeSet {
                deletePasscode()
            } else {
                createPasscode()
            }

        case .changePasscode:
            changePasscode()

        default:
            break
        }
    }
}
