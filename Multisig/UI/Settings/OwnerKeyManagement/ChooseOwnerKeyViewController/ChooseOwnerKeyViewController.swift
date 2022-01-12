//
//  ChooseOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/10/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class ChooseOwnerKeyViewController: UIViewController {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!

    private var owners: [KeyInfo] = []
    private var chainID: String?
    private var descriptionText: String!

    // technically it is possible to select several wallets but to finish connection with one of them
    private var walletPerTopic = [String: InstalledWallet]()
    // `wcDidConnectClient` happens when app eneters foreground. This parameter should throttle unexpected events
    private var waitingForSession = false

    var completionHandler: ((KeyInfo?) -> Void)?

    convenience init(owners: [KeyInfo], chainID: String?, descriptionText: String, completionHandler: ((KeyInfo?) -> Void)? = nil) {
        self.init()
        self.owners = owners
        self.chainID = chainID
        self.descriptionText = descriptionText
        self.completionHandler = completionHandler
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.chooseOwner)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select an owner key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        
        tableView.registerCell(ChooseOwnerTableViewCell.self)
        tableView.registerCell(SigningKeyTableViewCell.self)

        descriptionLabel.text = descriptionText
        descriptionLabel.setStyle(.primary)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(walletConnectSessionCreated(_:)),
            name: .wcDidConnectClient,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .wcDidDisconnectClient,
            object: nil)
    }

    @objc private func reload() {
        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        guard waitingForSession else { return }
        waitingForSession = false

        guard let session = notification.object as? Session,
              let account = Address(session.walletInfo?.accounts.first ?? ""),
              owners.first(where: { $0.address == account }) != nil else {
            WalletConnectClientController.shared.disconnect()
            DispatchQueue.main.async { [unowned self] in
                presentedViewController?.dismiss(animated: false, completion: nil)
                App.shared.snackbar.show(message: "Wrong wallet connected. Please try again.")
            }
            return
        }

        DispatchQueue.main.async { [unowned self] in
            // we need to update to always properly refresh session.walletInfo.peerId
            // that we use to identify if the wallet is connected
            _ = OwnerKeyController.updateKey(session: session,
                                             installedWallet: walletPerTopic[session.url.topic])

            // If the session is initiated with QR code, then we need to hide QR code controller
            if let presented = presentedViewController {                
                presented.dismiss(animated: false, completion: nil)
            }

            App.shared.snackbar.show(message: "Owner key wallet connected")
            tableView.reloadData()
        }
    }
}

extension ChooseOwnerKeyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        owners.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = owners[indexPath.row]
        let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configure(keyInfo: keyInfo, chainID: chainID)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyInfo = owners[indexPath.row]

        // For WalletConnect key check that it is still connected
        if keyInfo.keyType == .walletConnect {
            switch KeyConnectionStatus.init(keyInfo: keyInfo, chainID: chainID) {
            case .connected:
                completionHandler?(keyInfo)
            case .disconnected, .none:
                reconnect(key: keyInfo)
            case .connectionProblem:
                App.shared.snackbar.show(error: GSError.KeyConnectionProblem())
            }
        } else if keyInfo.keyType == .ledgerNanoX {
            completionHandler?(keyInfo)
        } else if App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            let vc = EnterPasscodeViewController()
            vc.passcodeCompletion = { [weak self] success in
                guard let `self` = self else { return }
                self.completionHandler?(success ? keyInfo : nil)
            }
            show(vc, sender: self)
        } else {
            completionHandler?(keyInfo)
        }
    }

    private func reconnect(key keyInfo: KeyInfo) {
        if let installedWallet = keyInfo.installedWallet {
            reconnectWithInstalledWallet(installedWallet)
        } else {
            showConnectionQRCodeController()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let keyInfo = owners[indexPath.row]
        guard keyInfo.keyType == .walletConnect else {
            return nil            
        }

        let isConnected = WalletConnectClientController.shared.isConnected(keyInfo: keyInfo)

        let action = UIContextualAction(style: .normal, title: isConnected ? "Disconnect" : "Connect") {
            [unowned self] _, _, completion in

            if isConnected {
                WalletConnectClientController.shared.disconnect()
            } else {
                reconnect(key: keyInfo)
            }

            completion(true)
        }
        action.backgroundColor = isConnected ? .orange : .button

        return UISwipeActionsConfiguration(actions: [action])
    }

    private func reconnectWithInstalledWallet(_ installedWallet: InstalledWallet) {
        guard let topic = WalletConnectClientController.reconnectWithInstalledWallet(installedWallet) else { return }
        walletPerTopic[topic] = installedWallet
        waitingForSession = true
    }

    private func showConnectionQRCodeController() {
        WalletConnectClientController.showConnectionQRCodeController(from: self) { result in
            switch result {
            case .success(_):
                waitingForSession = true
            case .failure(let error):
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not create connection URL", error: error))
            }
        }
    }
}
