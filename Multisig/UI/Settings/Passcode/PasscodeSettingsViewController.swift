//
//  PasscodeSettingsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import LocalAuthentication

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
        case requireForExportingKeys
        case oneOptionSelectedText
    }

    private var data: [(section: Section, rows: [Row])] = []

    private var isPasscodeSet: Bool {
        App.shared.auth.isPasscodeSetAndAvailable
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
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(reloadData), name: .biometricsActivated, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(reloadData), name: .passcodeDeleted, object: nil)

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsAppPasscode)
    }

    // MARK: - Actions

    @objc private func reloadData() {
        if isPasscodeSet {
            var lockRows: [Row] = [.usePasscode, .changePasscode]

            if App.shared.auth.isBiometricsSupported {
                lockRows.append(.loginWithBiometrics)
            }

            data = [
                (section: .lockMethod, rows: lockRows),
                (section: .usePasscodeFor, rows: [.requireToOpenApp, .requireForConfirmations, .requireForExportingKeys, .oneOptionSelectedText])
            ]

            // if user disables biometry, we can't keep it enabled in app settings.
            // Having this on reloadData() works because when biometry settings changed on the device
            // the system kills the app process and the app will have to restart.
            if !App.shared.auth.isBiometryActivationPossible {
                AppSettings.passcodeOptions.remove(.useBiometry)
            }
        } else {
            data = [
                (section: .single, rows: [.usePasscode, .helpText])
            ]
        }
        tableView.reloadData()
    }

    private func createPasscode() {
        let vc = CreatePasscodeViewController { [unowned self] in
            self.dismiss(animated: true) {
                self.reloadData()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    private func deletePasscode() {
        withPasscodeAuthentication(for: "Enter Passcode") { [unowned self] success, _, finish in
            if success {
                disablePasscode()
            }
            finish()
        }
    }

    private func disablePasscode() {
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

    private func changePasscode() {
        withPasscodeAuthentication(for: "Change Passcode", tracking: .changePasscode) { success, nav, finish in
            if success {
                let changeVC = ChangePasscodeEnterNewViewController {
                    finish()
                }
                nav?.pushViewController(changeVC, animated: true)
            } else {
                finish()
            }
        }
    }

    private func toggleUsage(option: PasscodeOptions, reason: String) {
        withPasscodeAuthentication(for: reason) { [unowned self] success, _, finish in
            if success && AppSettings.passcodeOptions.contains(option) {
                AppSettings.passcodeOptions.remove(option)
            } else if success {
                AppSettings.passcodeOptions.insert(option)
            }

            if AppSettings.passcodeOptions.isDisjoint(with: [.useForConfirmation, .useForLogin, .useForExportingKeys]) {
                disablePasscode()
            }

            finish()
            reloadData()
        }
    }

    private func toggleBiometrics() {
        withPasscodeAuthentication(for: "Login with biometrics") { [unowned self] success, nav, finish in
            let completion = { [unowned self] in
                finish()
                reloadData()
            }

            if success && AppSettings.passcodeOptions.contains(.useBiometry) {
                AppSettings.passcodeOptions.remove(.useBiometry)
                App.shared.snackbar.show(message: "Biometrics disabled.")
                completion()
            } else if success {
                App.shared.auth.activateBiometrics { result in
                    if hasFailedBecauseBiometryNotEnabled(result) {
                        showBiometrySettings(presenter: nav!, completion: completion)
                    } else {
                        completion()
                    }
                }
            } else {
                completion()
            }
        }
    }

    private func hasFailedBecauseBiometryNotEnabled(_ result: Result<Void, Error>) -> Bool {
        let FAILED_BECAUSE_BIOMETRY_NOT_ENABLED = true
        let FAILED_FOR_OTHER_REASON = false

        switch result {
        case .success:
            break

        case .failure(let error):

            switch error {
            case let gsError as GSError.BiometryActivationError:

                let underlyingError = gsError.underlyingError as NSError

                guard underlyingError.domain == LAErrorDomain else {
                    return FAILED_FOR_OTHER_REASON
                }

                let laError = LAError(_nsError: underlyingError)

                switch laError.code {
                case .biometryNotEnrolled, .passcodeNotSet:
                    return FAILED_BECAUSE_BIOMETRY_NOT_ENABLED

                default:
                    break
                }
            default:
                break
            }
        }
        return FAILED_FOR_OTHER_REASON
    }

    private func showBiometrySettings(presenter: UIViewController, completion: @escaping () -> Void) {
        let alertVC = UIAlertController(title: nil,
                                        message: "To activate biometry, navigate to Settings.",
                                        preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion()
        })
        let settings = UIAlertAction(title: "Settings", style: .default) { _ in
            // opens device settings
            let url = URL(string: UIApplication.openSettingsURLString)!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }

            completion()
        }
        alertVC.addAction(cancel)
        alertVC.addAction(settings)

        presenter.present(alertVC, animated: true, completion: nil)
    }

    /// Requests passcode entry from the user and returns whether the entry was successful
    /// - Parameters:
    ///   - reason: why the passcode is requested
    ///   - tracking: By default (nil) the passcode screen has `.enterPasscode` tracking event. This can override the tracking event.
    ///   - authenticated: completion block that is called when user enters the passcode or cancels it
    ///   - success: whether the entered passcode is correct
    ///   - nav: navigation controller that was presented. Sometimes you want to push other screen after the successful entry.
    ///   - finish: the closure that closes the presented passcode entry controller. You must call this closure when the flow is completed.
    private func withPasscodeAuthentication(
        for reason: String,
        tracking: TrackingEvent? = nil,
        authenticated: @escaping (_ success: Bool, _ nav: UINavigationController?, _ finish: @escaping () -> Void) -> Void
    ) {
        let vc = EnterPasscodeViewController()
        vc.usesBiometry = false
        vc.navigationItemTitle = reason
        if let event = tracking {
            vc.screenTrackingEvent = event
        }
        let nav = UINavigationController(rootViewController: vc)

        vc.passcodeCompletion = { [weak nav] success in
            authenticated(success, nav) {
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
            return tableView.switchCell(for: indexPath, with: "Use passcode", isOn: isPasscodeSet)

        case .changePasscode:
            return tableView.basicCell(name: "Change passcode", indexPath: indexPath)

        case .helpText:
            return tableView.helpCell(for: indexPath, with: "The passcode is needed to sign transactions.")

        case .loginWithBiometrics:
            return tableView.switchCell(for: indexPath,
                                        with: "Login with biometrics",
                                        isOn: AppSettings.passcodeOptions.contains(.useBiometry))

        case .requireToOpenApp:
            return tableView.switchCell(for: indexPath,
                                        with: "Require to open app",
                                        isOn: AppSettings.passcodeOptions.contains(.useForLogin))

        case .requireForConfirmations:
            return tableView.switchCell(for: indexPath,
                                        with: "Require for confirmations",
                                        isOn: AppSettings.passcodeOptions.contains(.useForConfirmation))
        case .requireForExportingKeys:
            return tableView.switchCell(for: indexPath,
                                        with: "Require for exporting keys",
                                        isOn: AppSettings.passcodeOptions.contains(.useForExportingKeys))

        case .oneOptionSelectedText:
            return tableView.helpCell(for: indexPath, with: "At least one option must be selected")
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

        case .loginWithBiometrics:
            toggleBiometrics()

        case .requireToOpenApp:
            toggleUsage(option: .useForLogin, reason: "Require to open app")

        case .requireForConfirmations:
            toggleUsage(option: .useForConfirmation, reason: "Require for confirmations")

        case .requireForExportingKeys:
            toggleUsage(option: .useForExportingKeys, reason: "Require for exporting keys")
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

    private func makeHeader(with text: String) -> BasicHeaderView {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(text)
        return view
    }
}
