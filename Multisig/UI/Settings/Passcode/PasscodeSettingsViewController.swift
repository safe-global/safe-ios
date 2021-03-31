//
//  PasscodeSettingsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PasscodeSettingsViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case single
        case lockMethod
        case usePasscodeFor
    }

    enum Row: Int, CaseIterable {
        case usePasscode
        case changePasscode
        case helpText
        case loginWithBiometrics
        case requireToOpenApp
        case requireForConfirmations
        case oneOptionSelectedText
    }

    private var data: [(section: Section, rows: [Row])] = []

    private var isPasscodeSet: Bool {
        App.shared.auth.isPasscodeSet
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Passcode"

        tableView.registerCell(SwitchTableViewCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.backgroundColor = .secondaryBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsAppPasscode)
    }

    // MARK: - Actions

    private func reloadData() {
        if isPasscodeSet {
            data = [
                (section: .lockMethod, rows: [.usePasscode, .changePasscode, .loginWithBiometrics]),
                (section: .usePasscodeFor, rows: [.requireToOpenApp, .requireForConfirmations, .oneOptionSelectedText])
            ]
        } else {
            data = [
                (section: .single, rows: [.usePasscode, .helpText])
            ]
        }
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

    // MARK: - Table view delegate and data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch data[indexPath.section].rows[indexPath.row] {
        case .usePasscode:
            return makeSwitch(for: indexPath, with: "Use passcode", isOn: isPasscodeSet)

        case .changePasscode:
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle("Change passcode")
            return cell

        case .helpText:
            return makeHelp(for: indexPath, with: "The passcode is needed to sign transactions.")

        case .loginWithBiometrics:
            return makeSwitch(for: indexPath, with: "Login with biometrics", isOn: false)

        case .requireToOpenApp:
            return makeSwitch(for: indexPath, with: "Require to open app", isOn: false)

        case .requireForConfirmations:
            return makeSwitch(for: indexPath, with: "Require for confirmations", isOn: false)

        case .oneOptionSelectedText:
            return makeHelp(for: indexPath, with: "At least one option must be selected")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch data[indexPath.section].rows[indexPath.row] {
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch data[section].section {
        case .single: return nil
        case .lockMethod: return makeHeader(with: "LOCK METHOD")
        case .usePasscodeFor: return makeHeader(with: "USE PASSCODE FOR")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch data[section].section {
        case .single: return 0
        default: return BasicHeaderView.headerHeight
        }
    }

    // MARK: - Factory methods

    private func makeSwitch(for indexPath: IndexPath, with text: String, isOn: Bool) -> SwitchTableViewCell {
        let cell = tableView.dequeueCell(SwitchTableViewCell.self, for: indexPath)
        cell.setText(text)
        cell.setOn(isOn, animated: false)
        return cell
    }

    private func makeHelp(for indexPath: IndexPath, with text: String) -> UITableViewCell {
        let cell = tableView.dequeueCell(UITableViewCell.self, reuseID: "HelpCell", for: indexPath)
        cell.textLabel?.setStyle(.secondary)
        cell.backgroundColor = .primaryBackground
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }

    private func makeHeader(with text: String) -> BasicHeaderView {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(text)
        return view
    }
}
