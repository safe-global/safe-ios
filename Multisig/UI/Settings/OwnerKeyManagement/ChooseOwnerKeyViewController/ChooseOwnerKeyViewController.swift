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
            self, selector: #selector(walletConnectSessionCreated(_:)), name: .wcDidConnectClient, object: nil)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        guard let session = notification.object as? Session else { return }

        DispatchQueue.main.async { [unowned self] in
            // we need to update to always properly refresh session.walletInfo.peedId
            // that we use to identify if the wallet is connected
            _ = PrivateKeyController.updateKey(session: session,
                                               installedWallet: walletPerTopic[session.url.topic])
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
        if App.configuration.toggles.walletConnectEnabled {
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
        if App.configuration.toggles.walletConnectEnabled && keyInfo.keyType == .walletConnect {
            guard WalletConnectClientController.shared.isConnected(keyInfo: keyInfo) else {
                // try to reconnect

                if let installedWallet = WalletsDataSource.shared.installedWallet(by: keyInfo) {
                    // TODO:
                    // show alert offering one of two actoins:
                    // - connect to installed wallet
                    // - show QR code

                    do {
                        let (topic, connectionURL) = try WalletConnectClientController.shared
                            .getTopicAndConnectionURL(universalLink: installedWallet.universalLink)
                        walletPerTopic[topic] = installedWallet
                        UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
                    } catch {
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Could not create connection URL", error: error))
                    }
                } else {
                    // TODO: show QR code
                }

                return
            }
        }

        if App.shared.auth.isPasscodeSet && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            let vc = EnterPasscodeViewController()
            vc.completion = { [weak self] success in
                guard let `self` = self else { return }
                self.completionHandler?(success ? keyInfo : nil)
            }
           show(vc, sender: self)
        } else {
            completionHandler?(keyInfo)
        }
    }
}
