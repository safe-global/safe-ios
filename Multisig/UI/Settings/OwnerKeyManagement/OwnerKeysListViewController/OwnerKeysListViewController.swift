//
//  OwnerKeysListViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class OwnerKeysListViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource, PasscodeProtecting {
    private var keys: [KeyInfo] = []
    private var chainID: String?
    private var addButton: UIBarButtonItem!
    private var backupFlow: ModalBackupFlow!

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

        tableView.backgroundColor = .backgroundPrimary

        tableView.registerCell(SigningKeyTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200

        emptyView.setTitle("There are no added owner keys")
        emptyView.setImage(UIImage(named: "ico-no-keys")!)

        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton(_:)))
        navigationItem.rightBarButtonItem = addButton

        for notification in [NSNotification.Name.selectedSafeChanged,
                                .selectedSafeUpdated,
                                .ownerKeyImported,
                                .ownerKeyRemoved,
                                .ownerKeyUpdated,
                                .ownerKeyBackedUp] {
            notificationCenter.addObserver(self, selector: #selector(lazyReloadData), name: notification, object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerKeysList)
    }

    @objc private func didTapAddButton(_ sender: Any) {
        let vc = ViewControllerFactory.addOwnerViewController { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
        present(vc, animated: true)
    }

    override func reloadData() {
        super.reloadData()
        keys = (try? KeyInfo.all()) ?? []
        chainID = try? Safe.getSelected()?.chain?.id
        setNeedsReload(false)
        onSuccess()
        tableView.reloadData()
    }

    @objc private func reload() {
        DispatchQueue.main.async { [unowned self] in
            self.reloadData()
        }
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = keys[indexPath.row]
        let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configure(keyInfo: keyInfo, chainID: chainID) { [weak self] in
            self?.startBackup(keyInfo: keyInfo)
        }
        return cell
    }

    private func startBackup(keyInfo: KeyInfo) {
        Tracker.trackEvent(.backupFromKeysList)

        keyInfo.privateKey { [unowned self] result in
            guard let mnemonic = try? result.get()?.mnemonic else {
                return
            }
            backupFlow = ModalBackupFlow(mnemonic: mnemonic) { [unowned self] success in
                self.backupFlow = nil
            }
            backupFlow?.modal(from: self)
        }
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyInfo = keys[indexPath.row]
        let vc = OwnerKeyDetailsViewController(keyInfo: keyInfo)
        show(vc, sender: self)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let keyInfo = keys[indexPath.row]

        var actions = [UIContextualAction]()
        let editAction = UIContextualAction(style: .normal, title: "Rename") { [unowned self] _, _, completion in
            let vc = EditOwnerKeyViewController(keyInfo: self.keys[indexPath.row])
            self.show(vc, sender: self)
            completion(true)
        }
        actions.append(editAction)

        if keyInfo.keyType == .walletConnect {
            let isConnected = keyInfo.connectedAsDapp

            let wcAction = UIContextualAction(style: .normal, title: isConnected ? "Disconnect" : "Connect") {
                [unowned self] _, _, completion in

                if isConnected {
                    let alertController = DisconnectionConfirmationController.create(key: keyInfo)
                    if let popoverPresentationController = alertController.popoverPresentationController {
                        popoverPresentationController.sourceView = tableView
                        popoverPresentationController.sourceRect = tableView.rectForRow(at: indexPath)
                    }

                    self.present(alertController, animated: true)
                } else {
                    self.connect(keyInfo: keyInfo)
                }

                completion(true)
            }
            wcAction.backgroundColor = isConnected ? .orange : .success
            actions.append(wcAction)
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.remove(key: keyInfo)
            completion(true)
        }
        actions.append(deleteAction)

        return UISwipeActionsConfiguration(actions: actions)
    }

    func connect(keyInfo: KeyInfo) {
        let wcWallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        let chain = Selection.current().safe?.chain ?? Chain.mainnetChain()
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wcWallet, chain: chain, keyInfo: keyInfo)
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: wcWallet != nil)
        present(vc, animated: true)
    }

    private func remove(key: KeyInfo) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .multiplatformActionSheet)

        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            OwnerKeyController.remove(keyInfo: key)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

}
