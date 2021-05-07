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
    private var installedWallets = WalletsDataSource.shared.installedWallets

    private var walletPerTopic = [String: InstalledWallet]()

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

    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        guard let session = notification.object as? Session else { return }

        DispatchQueue.main.sync { [unowned self] in
            _ = PrivateKeyController.importKey(session: session, installedWallet: walletPerTopic[session.url.topic])
            self.dismiss(animated: true, completion: nil)
        }
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
                let (topic, connectionURL) = try WalletConnectClientController.shared
                    .getTopicAndConnectionURL(universalLink: installedWallets[indexPath.row].universalLink)
                walletPerTopic[topic] = installedWallets[indexPath.row]
                // we need a delay so that WalletConnectClient can send handshake request
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
                }
            } else {
                let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
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
        view.setName(section == 0 ? "INSTALLED WALLETS" : "EXTERNAL DEVICE")
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }
}
