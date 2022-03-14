//
//  ConnectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class ConnectWalletViewController: LoadableViewController {
    private var completion: () -> Void = { }

    let searchController = UISearchController(searchResultsController: nil)

    private var searchTerm: String? {
        guard let term = searchController.searchBar.text?.lowercased(), !term.isEmpty else { return nil }
        return term
    }

    private let walletsSource = WCRegistryController()
    private var wallets: [WCAppRegistryEntry] = []

    var sections: [ConnectWalletSection] = []

    override var isEmpty: Bool { wallets.isEmpty }

    convenience init(completion: @escaping () -> Void) {
        self.init(namedClass: Self.superclass())
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Wallet"

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(BasicCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.rowHeight = 60

        navigationItem.searchController = searchController
        navigationItem.backButtonTitle = "Back"


        emptyView.setImage(UIImage(named: "ico-wallet-placeholder")!)
        emptyView.setText("No wallets found")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"

        walletsSource.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectKeyOptions)
    }

    override func reloadData() {
        walletsSource.loadData()
    }
}

extension ConnectWalletViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].type == .qrCode ? 1 : sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].type {
            case.qrCode:
                return tableView.basicCell(
                            name: "Display QR Code",
                            icon: "qrcode",
                            indexPath: indexPath,
                            withDisclosure: false,
                            canSelect: false
                        )
            default:
                let wallet = sections[indexPath.section].rows[indexPath.row]
                return tableView.basicCell(
                            name: wallet.name,
                            iconURL: wallet.imageSmallUrl,
                            placeholder: UIImage(named: "ico-wallet-placeholder")!,
                            indexPath: indexPath,
                            withDisclosure: false,
                            canSelect: false
                        )
        }
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        do {
            switch sections[indexPath.section].type {
            case .qrCode:
                let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
                show(WalletConnectQRCodeViewController.create(code: connectionURI), sender: nil)
            default:
                let wallet = sections[indexPath.section].rows[indexPath.row]
                if wallet.installed {
                    // TODO: Create connection request
                } else if let storeURL = wallet.appStoreLink {
                    UIApplication.shared.open(storeURL, options: [:], completionHandler: nil)
                } else if let homePage = wallet.homepage {
                    UIApplication.shared.open(homePage, options: [:], completionHandler: nil)
                } else {
                    App.shared.snackbar.show(message: "Wallet not installed and store link is missing")
                }
            }
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Could not create connection URL", error: error))
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = sections[section].title
        if title.isEmpty { return nil }
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(title)

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].title.isEmpty { return 0 }
        return BasicHeaderView.headerHeight
    }

    func bindData() {
        wallets = walletsSource.wallets(searchTerm)
        if searchTerm == nil {
            sections = [.init(type: .qrCode, title: "", rows: []),
                        .init(type: .installedWallets, title: "ON THIS DEVICE", rows: wallets.filter { $0.installed }),
                        .init(type: .otherWallets, title: "OTHER WALLETS", rows: wallets.filter { !$0.installed })]
        } else {
            sections = [.init(type: .all, title: "", rows: wallets)]
        }

        if isEmpty {
            showOnly(view: emptyView)
        } else {
            showOnly(view: tableView)
        }

        tableView.reloadData()
    }
}

extension ConnectWalletViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        bindData()
    }
}

extension ConnectWalletViewController: WCRegistryControllerDelegate {
    func didUpdate(controller: WCRegistryController) {
        bindData()
    }

    func didFailToLoad(controller: WCRegistryController, error: Error) {
        App.shared.snackbar.show(error: GSError.error(description: "Failed to load wallets",
                                                      error: error.localizedDescription))
        bindData()
    }
}

extension WCAppRegistryEntry {
    var installed: Bool {
        linkMobileNative != nil && UIApplication.shared.canOpenURL(linkMobileNative!)
    }
}

enum ConnectWalletSectionType {
    case qrCode
    case installedWallets
    case otherWallets
    case all
}

struct ConnectWalletSection {
    let type: ConnectWalletSectionType
    let title: String
    let rows: [WCAppRegistryEntry]
}
