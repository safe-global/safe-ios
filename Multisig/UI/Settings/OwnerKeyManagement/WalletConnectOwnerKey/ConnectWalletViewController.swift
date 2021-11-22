//
//  ConnectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class ConnectWalletViewController: UITableViewController {
    private var completion: () -> Void = { }
    private var installedWallets = WalletsDataSource.shared.installedWallets

    // technically it is possible to select several wallets but to finish connection with one of them
    private var walletPerTopic = [String: InstalledWallet]()
    // `wcDidConnectClient` happens when app eneters foreground. This parameter should throttle unexpected events
    private var waitingForSession = false

    convenience init(completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Wallet"

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DetailedCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.rowHeight = DetailedCell.rowHeight

        NotificationCenter.default.addObserver(
            self, selector: #selector(walletConnectSessionCreated(_:)), name: .wcDidConnectClient, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectKeyOptions)
    }

    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        guard let session = notification.object as? Session, waitingForSession else { return }
        waitingForSession = false

        DispatchQueue.main.sync { [weak self] in
            self?.enterName(for: session)
        }
    }

    /// Gets the name from user and imports the key
    private func enterName(for session: Session) {
        // get the address of the connected wallet
        guard let walletInfo = session.walletInfo,
              let address = walletInfo.accounts.first.flatMap(Address.init) else {
                  App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
            return
        }

        let enterAddressVC = EnterAddressNameViewController()
        enterAddressVC.actionTitle = "Import"
        enterAddressVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterAddressVC.screenTitle = "Enter Key Name"
        enterAddressVC.trackingEvent = .enterKeyName

        enterAddressVC.placeholder = "Enter name"
        enterAddressVC.name = walletInfo.peerMeta.name
        enterAddressVC.address = address
        enterAddressVC.badgeName = KeyType.deviceImported.imageName
        enterAddressVC.completion = { [unowned self] name in
            let success = OwnerKeyController.importKey(session: session,
                                                         installedWallet: self.walletPerTopic[session.url.topic],
                                                         name: name)

            if success {
                App.shared.snackbar.show(message: "The key added successfully")
            }

            self.completion()
        }

        show(enterAddressVC, sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return installedWallets.count != 0 ? installedWallets.count : 1
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if installedWallets.count != 0 {
                let wallet = installedWallets[indexPath.row]
                return tableView.detailedCell(
                    imageUrl: nil,
                    header: wallet.name,
                    description: nil,
                    indexPath: indexPath,
                    canSelect: false,
                    placeholderImage: UIImage(named: wallet.imageName))
            } else {
                return tableView.basicCell(
                    name: "Known wallets not found", indexPath: indexPath, withDisclosure: false, canSelect: false)
            }
        } else {
            return tableView.detailedCell(
                imageUrl: nil,
                header: "Display QR Code",
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(systemName: "qrcode"))
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        do {
            if indexPath.section == 0 {
                guard !installedWallets.isEmpty else { return }
                let installedWallet = installedWallets[indexPath.row]
                let link = installedWallet.universalLink.isEmpty ?
                    installedWallet.scheme :
                    installedWallet.universalLink

                let (topic, connectionURL) = try WalletConnectClientController.shared.connectToWallet(link: link)
                walletPerTopic[topic] = installedWallet
                waitingForSession = true

                // we need a delay so that WalletConnectClient can send handshake request
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
                }
            } else {
                let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
                waitingForSession = true
                show(WalletConnectQRCodeViewController.create(code: connectionURI), sender: nil)
            }
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not create connection URL", error: error))
            return
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(section == 0 ? "ON THIS DEVICE" : "ON OTHER DEVICE")
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }
}
