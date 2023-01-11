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
        case passcode
        case usePasscodeFor
    }

    enum Row: Int, CaseIterable {
        case usePasscode
        case changePasscode
        case loginWithBiometrics
        case lockMethod
        case requireToOpenApp
        case requireForConfirmations
        case oneOptionSelectedText
    }

    enum LockMethod {
        case passcode
        case userPresence
        case passcodeAndUserPresence

    }

    enum BiometryType {
        case faceID
        case touchID
        case passcode

        var name: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .passcode: return "Device Passcode"
            }
        }
    }

    // TODO: sync the values with the SecurityCenter
    private var lock: LockMethod = .passcode
    private var biometryType: BiometryType = .passcode

    private var data: [(section: Section, rows: [Row])] = []
    private var createPasscodeFlow: CreatePasscodeFlow!

    private var isPasscodeSet: Bool {
        App.shared.auth.isPasscodeSetAndAvailable
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Security"

        tableView.registerCell(SwitchTableViewCell.self)
        tableView.registerCell(SwitchDetailedTableViewCell.self)
        tableView.registerCell(MenuTableViewCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.backgroundColor = .backgroundPrimary
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

        // uncomment to cycle through the detail texts
        // _cycleThroughLockMethodAndBiometryTexts()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsAppPasscode)
    }

    // MARK: - Actions

    @objc private func reloadData() {
        if isPasscodeSet {
            data = [
                (section: .lockMethod, rows: [.usePasscode, .lockMethod]),
                (section: .passcode, rows: [.changePasscode]),
                (section: .usePasscodeFor, rows: [.requireToOpenApp, .requireForConfirmations, .oneOptionSelectedText])
            ]

            // if user disables biometry, we can't keep it enabled in app settings.
            // Having this on reloadData() works because when biometry settings changed on the device
            // the system kills the app process and the app will have to restart.
            if !App.shared.auth.isBiometryActivationPossible {
                AppSettings.passcodeOptions.remove(.useBiometry)
            }
        } else {
            data = [
                (section: .single, rows: [.usePasscode])
            ]
        }
        tableView.reloadData()
    }

    private func createPasscode() {
        createPasscodeFlow = CreatePasscodeFlow(completion: { [unowned self] _ in
            createPasscodeFlow = nil
            reloadData()
        })
        present(flow: createPasscodeFlow)
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

            if AppSettings.passcodeOptions.isDisjoint(with: [.useForConfirmation, .useForLogin]) {
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

        vc.passcodeCompletion = { [weak nav] success, _ in
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

    // Helper function to test effects of all combinations of the lock method and biometry settings on the UI
    func _cycleThroughLockMethodAndBiometryTexts() {
        DispatchQueue.global().async {
            for cycleCounter in (0..<99) {
                let locks: [LockMethod] = [.passcode, .userPresence, .passcodeAndUserPresence]
                let biometries: [BiometryType] = [.passcode, .touchID, .faceID]

                // Display each combination for 5 seconds
                for lock in locks {
                    for biometry in biometries {

                        // update the UI with new simulated parameters
                        DispatchQueue.main.async { [unowned self] in
                            print("Cycle", cycleCounter, "Lock", lock, "Biometry", biometry)


                            self.lock = lock
                            self.biometryType = biometry
                            self.reloadData()
                        }

                        Thread.sleep(forTimeInterval: 5)
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: get selected lock method from the security center
        let row = data[indexPath.section].rows[indexPath.row]
        let detail = detailText(for: row, lock: lock, biometry: biometryType)

        switch row {
        case .usePasscode:
            return switchDetailCell(
                for: indexPath,
                with: "Enable security lock",
                detail: detail,
                isOn: isPasscodeSet)

        case .changePasscode:
            return tableView.basicCell(name: "Change passcode", indexPath: indexPath)

        case .loginWithBiometrics:
            return tableView.switchCell(for: indexPath,
                                        with: "Login with biometrics",
                                        isOn: AppSettings.passcodeOptions.contains(.useBiometry))

        case .lockMethod:
            let cell = tableView.dequeueCell(MenuTableViewCell.self, for: indexPath)
            cell.titleLabel.setStyle(.headline)
            cell.titleLabel.text = "Lock method"
            cell.button.setText(detail!, .plain)

            cell.button.setTitle(detail, for: .normal)
            cell.button.showsMenuAsPrimaryAction = true
            let menu = UIMenu(title: "", children: [
                UIAction(title: detailText(for: .lockMethod, lock: .passcode, biometry: biometryType)!) { action in
                    // TODO: change to passcode
                },
                UIAction(title: detailText(for: .lockMethod, lock: .userPresence, biometry: biometryType)!) { action in
                    // TODO: change to biometry
                },
                UIAction(title: detailText(for: .lockMethod, lock: .passcodeAndUserPresence, biometry: biometryType)!) { action in
                    // TODO: change to passcode & user presence
                }
            ])
            cell.button.isContextMenuInteractionEnabled
            cell.button.menu = menu
            return cell

        case .requireToOpenApp:
            return switchDetailCell(for: indexPath,
                                    with: "Unlocking the app",
                                    detail: detail,
                                    isOn: AppSettings.passcodeOptions.contains(.useForLogin))

        case .requireForConfirmations:
            return switchDetailCell(for: indexPath,
                                    with: "Making transactions",
                                    detail: detail,
                                    isOn: AppSettings.passcodeOptions.contains(.useForConfirmation))

        case .oneOptionSelectedText:
            return tableView.helpCell(
                for: indexPath,
                with: "At least one setting must be enabled.",
                hasSeparator: false)
        }
    }


    func detailText(for row: Row, lock: LockMethod, biometry: BiometryType) -> String? {
        switch row {
        case .lockMethod:
            switch lock {
            case .passcode:
                return "Passcode"
            case .userPresence:
                return biometry.name
            case .passcodeAndUserPresence:
                return "Passcode & \(biometry.name)"
            }
            
        case .usePasscode:
            let text = biometry == .passcode ? "" : "or \(biometry.name) "
            return "Require passcode \(text)for unlocking the app, making transactions and using signer accounts"

        case .requireToOpenApp:
            let text: String
            switch lock {
            case .passcode: text = "Passcode"
            case .userPresence: text = biometry.name
            case .passcodeAndUserPresence: text = biometry.name
            }
            return "Only \(text) will be required to unlock the app."

        case .requireForConfirmations:
            let text: String
            switch lock {
            case .passcode: text = "Passcode"
            case .userPresence: text = biometry.name
            case .passcodeAndUserPresence: text = "Both Passcode & \(biometry.name)"
            }
            return "\(text) will be used for making transactions."

        default:
            return nil
        }
    }

    func switchDetailCell(for indexPath: IndexPath, with text: String, detail: String? = nil, isOn: Bool) -> SwitchDetailedTableViewCell {
        let cell = tableView.dequeueCell(SwitchDetailedTableViewCell.self, for: indexPath)
        cell.text = text
        cell.detailText = detail
        cell.setOn(isOn, animated: false)
        return cell
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

        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch data[section].section {
        case .single: return nil
        case .lockMethod: return makeHeader(with: "LOCK METHOD")
        case .passcode: return makeHeader(with: "PASSCODE")
        case .usePasscodeFor: return makeHeader(with: "REQUIRE LOCK METHOD FOR...")
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
