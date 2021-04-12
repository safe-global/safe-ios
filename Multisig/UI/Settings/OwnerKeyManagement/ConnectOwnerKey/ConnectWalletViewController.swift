//
//  ConnectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate struct InstalledWallet {
    let imageUrl: URL
    let name: String
    let scheme: String
    let universalLink: String

    init?(walletEntry: WalletEntry) {
        let homepage = walletEntry.homepage
        let name = walletEntry.name
        let scheme = walletEntry.mobile.native
        let universalLink = walletEntry.mobile.universal
        let faviconPath = homepage.last == "/" ? "favicon.ico" : "/favicon.ico"

        guard let imageUrl = URL(string: homepage + faviconPath),
              let schemeUrl = URL(string: scheme),
              UIApplication.shared.canOpenURL(schemeUrl),
              !universalLink.isEmpty else { return nil }

        self.imageUrl = imageUrl
        self.name = name
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
                imageUrl: wallet.imageUrl,
                header: wallet.name,
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: "ico-empty-circle"))
        } else {
            return UITableViewCell()
        }
    }
}
