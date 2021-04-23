//
//  OwnerKeysListViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class OwnerKeysListViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    private var keys: [KeyInfo] = []
    private var addButton: UIBarButtonItem!
    override var isEmpty: Bool {
        keys.isEmpty
    }
    
    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Owner Keys"
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .primaryBackground

        tableView.registerCell(OwnerKeysListTableViewCell.self)
        tableView.registerCell(SigningKeyTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setText("There are no imported owner keys")
        emptyView.setImage(#imageLiteral(resourceName: "ico-no-keys"))

        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton(_:)))
        navigationItem.rightBarButtonItem = addButton

        notificationCenter.addObserver(
            self,
            selector: #selector(lazyReloadData),
            name: .ownerKeyImported,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(lazyReloadData),
            name: .ownerKeyRemoved,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(lazyReloadData),
            name: .ownerKeyUpdated,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerKeysList)
    }

    @objc private func didTapAddButton(_ sender: Any) {
        let vc = ViewControllerFactory.selectKeyTypeViewController(presenter: self)
        present(vc, animated: true)
    }

    override func reloadData() {
        super.reloadData()
        keys = (try? KeyInfo.all()) ?? []
        setNeedsReload(false)
        onSuccess()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = keys[indexPath.row]
        if App.configuration.toggles.walletConnectEnabled {
            let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none

            cell.set(address: keyInfo.address, title: keyInfo.displayName)

            switch keyInfo.keyType {
            case .device:
                cell.set(keyImageUrl: nil, placeholder: UIImage(named: "ico-device-key")!)
                cell.set(wcConnectionStatus: .none)

            case .walletConnect:
                cell.set(keyImageUrl: nil, placeholder: UIImage(named: "wc-logo")!)
                if let metadata = keyInfo.metadata,
                   let walletInfo = Session.WalletInfo.from(data: metadata) {
                    let isConnected = WalletConnectClientController.shared.isConnected(peerId: walletInfo.peerId)
                    cell.set(wcConnectionStatus: isConnected ? .connected : .disconnected)
                } else {
                    // might happen if WalletInfo structure changes with library update
                    cell.set(wcConnectionStatus: .disconnected)
                }
            }

            return cell
        } else {
            let cell = tableView.dequeueCell(OwnerKeysListTableViewCell.self, for: indexPath)

            cell.set(address: keyInfo.address, title: keyInfo.displayName)
            cell.delegate = self

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if App.configuration.toggles.walletConnectEnabled {
            let vc = EditOwnerKeyViewController(keyInfo: keys[indexPath.row])
            show(vc, sender: self)
        }
    }

    private func remove(key: KeyInfo) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            PrivateKeyController.remove(keyInfo: key)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension OwnerKeysListViewController: OwnerKeysListTableViewCellDelegate {
    func ownerKeysListTableViewDidEdit(cell: OwnerKeysListTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let vc = EditOwnerKeyViewController(keyInfo: keys[indexPath.row])
        show(vc, sender: self)
    }

    func ownerKeysListTableViewCellDidRemove(cell: OwnerKeysListTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        remove(key: keys[indexPath.row])
    }
}
