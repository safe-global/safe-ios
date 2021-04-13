//
//  ConnectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate struct InstalledWallet {
    let name: String
    let imageName: String
    let scheme: String
    let universalLink: String

    init?(walletEntry: WalletEntry) {
        let scheme = walletEntry.mobile.native
        var universalLink = walletEntry.mobile.universal
        if universalLink.last == "/" {
            universalLink = String(universalLink.dropLast())
        }

        guard let schemeUrl = URL(string: scheme),
              UIApplication.shared.canOpenURL(schemeUrl),
              !universalLink.isEmpty else { return nil }

        self.name = walletEntry.name
        self.imageName = walletEntry.imageName
        self.scheme = scheme
        self.universalLink = universalLink
    }
}

class ConnectWalletViewController: UITableViewController {
    private var installedWallets = [InstalledWallet]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Wallet"

        installedWallets = WalletsDataSource.shared.wallets.compactMap {
            InstalledWallet(walletEntry: $0)
        }

        tableView.registerCell(DetailedCell.self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return installedWallets.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let wallet = installedWallets[indexPath.row]
            return tableView.detailedCell(
                imageUrl: nil,
                header: wallet.name,
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: wallet.imageName))
        } else {
            return UITableViewCell()
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let wallet = installedWallets[indexPath.row]
            do {
                let connectionURL = try getConnectionURL(universalLink: wallet.universalLink)
                print("LINK: \(connectionURL.absoluteString)")
                UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
            } catch {
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not create connection URL", error: error))
            }
        } else {
            // show QR code screen
        }
    }

    private func getConnectionURL(universalLink: String) throws -> URL {
        let connectionUrlString = try WalletConnectClientController.shared.connect()

        // https://docs.walletconnect.org/mobile-linking#for-ios
        return URL(string: "\(universalLink)/wc?uri=\(connectionUrlString)")!
    }
}
