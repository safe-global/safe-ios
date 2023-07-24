//
//  SelectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class SelectWalletViewController: LoadableViewController {
    private var completion: (_ wallet: WCAppRegistryEntry?, _ connection: WebConnection) -> Void = { _, _ in }
    private var connection: WebConnection?

    let searchController = UISearchController(searchResultsController: nil)

    private var searchTerm: String? {
        guard let term = searchController.searchBar.text?.lowercased(), !term.isEmpty else { return nil }
        return term
    }

    private let walletsSource = WCRegistryController()
    private var wallets: [WCAppRegistryEntry] = []

    var sections: [ConnectWalletSection] = []

    override var isEmpty: Bool { wallets.isEmpty }

    convenience init(completion: @escaping (_ wallet: WCAppRegistryEntry?, _ connection: WebConnection) -> Void) {
        self.init(namedClass: Self.superclass())
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Wallet"

        tableView.backgroundColor = .backgroundPrimary
        tableView.registerCell(BasicCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.rowHeight = 60

        navigationItem.searchController = searchController
        navigationItem.backButtonTitle = "Back"
        navigationItem.hidesSearchBarWhenScrolling = false

        emptyView.setImage(UIImage(named: "ico-wallet-placeholder")!)
        emptyView.setTitle("No wallets found")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = false

        walletsSource.delegate = self

        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navigationController?.navigationBar.backgroundColor = .backgroundSecondary
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectKeyOptions)
    }

    override func reloadData() {
        super.reloadData()
        walletsSource.loadData()
    }

    func cancelExistingConnection() {
        guard let connection = connection else {
            return
        }
        WebConnectionController.shared.userDidCancel(connection)
    }
}

extension SelectWalletViewController: UITableViewDelegate, UITableViewDataSource {
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
                name: "Show QR Code",
                icon: "qrcode",
                indexPath: indexPath,
                disclosureImage: nil,
                canSelect: false
            )
        default:
            let wallet = sections[indexPath.section].rows[indexPath.row]
            return tableView.basicCell(
                name: wallet.name,
                iconURL: wallet.imageSmallUrl,
                placeholder: UIImage(named: "ico-wallet-placeholder")!,
                indexPath: indexPath,
                disclosureImage: nil,
                canSelect: false
            )
        }
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section].type {
        case .qrCode:
            showQRCode()
        default:
            let wallet = sections[indexPath.section].rows[indexPath.row]
            if wallet.linkMobileNative != nil || wallet.linkMobileUniversal != nil {
                connect(to: wallet)
            } else if let url = wallet.appStoreLink ?? wallet.homepage {
                open(url: url)
            } else {
                App.shared.snackbar.show(message: "Wallet is not installed and store link is missing")
            }
        }
    }

    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func showQRCode() {
        connect(to: nil)
    }

    func connect(to wallet: WCAppRegistryEntry?) {
        cancelExistingConnection()
        let chain = Selection.current().safe?.chain ?? Chain.mainnetChain()
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain)
        walletConnectionVC.onSuccess = { [weak self] connection in
            var connectedWallet = wallet
            self?.connection = connection
            self?.completion(wallet, connection)
        }
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: wallet != nil)
        present(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = sections[section].title
        if title.isEmpty || sections[section].rows.isEmpty { return nil }
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(title)

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].title.isEmpty || sections[section].rows.isEmpty { return 0 }
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

extension SelectWalletViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        bindData()
    }
}

extension SelectWalletViewController: WCRegistryControllerDelegate {
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
