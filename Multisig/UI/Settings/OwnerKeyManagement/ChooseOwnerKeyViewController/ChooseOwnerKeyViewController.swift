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
    private var descriptionText: String!
    private var walletPerTopic = [String: InstalledWallet]()
    private var waitingForSession = false

    var completionHandler: ((KeyInfo?) -> Void)?

    convenience init(owners: [KeyInfo], descriptionText: String, completionHandler: ((KeyInfo?) -> Void)? = nil) {
        self.init()
        self.owners = owners
        self.descriptionText = descriptionText
        self.completionHandler = completionHandler
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.chooseOwner)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select owner key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(didTapCloseButton))
        
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
                self.hidePresentedIfNeeded()
                App.shared.snackbar.show(message: "Wrong wallet connected. Please try again.")
            }
            return
        }

        DispatchQueue.main.async { [unowned self] in
            // we need to update to always properly refresh session.walletInfo.peedId
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
        if App.configuration.toggles.walletConnectOwnerKeyEnabled {
            let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.configure(keyInfo: keyInfo)
            return cell
        } else {
            let cell = tableView.dequeueCell(ChooseOwnerTableViewCell.self)
            cell.set(address: keyInfo.address, title: keyInfo.displayName)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyInfo = owners[indexPath.row]

        // For WalletConnect key check that it is still connected
        if App.configuration.toggles.walletConnectOwnerKeyEnabled && keyInfo.keyType == .walletConnect {
            guard WalletConnectClientController.shared.isConnected(keyInfo: keyInfo) else {
                // try to reconnect
                if let installedWallet = keyInfo.installedWallet {
                    reconnectWithInstalledWallet(installedWallet)
                } else {
                    showConnectionQRCodeController()
                }
                return
            }

            // do not request passcode for connected wallets
            // as they have own protection
            completionHandler?(keyInfo)
            return
        }

        if App.shared.auth.isPasscodeSet && AppSettings.passcodeOptions.contains(.useForConfirmation) {
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

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let keyInfo = owners[indexPath.row]
        guard App.configuration.toggles.walletConnectOwnerKeyEnabled && keyInfo.keyType == .walletConnect else {
            return nil            
        }

        let isConnected = WalletConnectClientController.shared.isConnected(keyInfo: keyInfo)

        let action = UIContextualAction(style: .normal, title: isConnected ? "Disconnect" : "Connect") {
            [unowned self] _, _, completion in

            if isConnected {
                WalletConnectClientController.shared.disconnect()
            } else {
                // try to reconnect
                if let installedWallet = keyInfo.installedWallet {
                    self.reconnectWithInstalledWallet(installedWallet)
                } else {
                    self.showConnectionQRCodeController()
                }
            }

            completion(true)
        }
        action.backgroundColor = isConnected ? .orange : .button

        return UISwipeActionsConfiguration(actions: [action])
    }

    #warning("TODO: move - code duplication")
    private func reconnectWithInstalledWallet(_ installedWallet: InstalledWallet) {
        do {
            let link = installedWallet.universalLink.isEmpty ? installedWallet.scheme : installedWallet.universalLink
            let (topic, connectionURL) = try WalletConnectClientController.shared
                .getTopicAndConnectionURL(link: link)
            walletPerTopic[topic] = installedWallet
            waitingForSession = true
            // we need a delay so that WalletConnectClient can send handshake request
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
            }
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not create connection URL", error: error))
        }
    }

    private func showConnectionQRCodeController() {
        do {
            let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
            let qrCodeVC = WalletConnectQRCodeViewController.create(code: connectionURI)
            waitingForSession = true
            present(qrCodeVC, animated: true, completion: nil)
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not create connection URL", error: error))
        }
    }

    private func hidePresentedIfNeeded() {
        if let presented = presentedViewController {
            presented.dismiss(animated: false, completion: nil)
        }
    }
}
