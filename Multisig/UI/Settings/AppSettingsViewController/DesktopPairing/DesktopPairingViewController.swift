//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class DesktopPairingViewController: UITableViewController {
    private var sessions = [WCKeySession]()
    private let wcServerController = WalletConnectKeysServerController.shared
    private lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Desktop Pairing"

        wcServerController.delegate = self

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DetailedCell.self)
        tableView.registerHeaderFooterView(DesktopPairingHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        subscribeToNotifications()
        update()
    }

    private func subscribeToNotifications() {
        [NSNotification.Name.wcConnectingKeyServer,
         .wcDidConnectKeyServer,
         .wcDidDisconnectKeyServer,
         .wcDidFailToConnectKeyServer].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(update), name: $0, object: nil)
         }
    }

    @objc private func update() {
        do {
            sessions = try WCKeySession.getAll().filter {
                $0.session != nil && (try? Session.from($0)) != nil
            }
        } catch {
            LogService.shared.error("Failed to get WCKeySession: \(error.localizedDescription)")
        }

        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    private func scan() {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { value in
            guard value.starts(with: "wc:") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = sessions[indexPath.row]

        switch session.status {
        case .connecting:
            return tableView.detailedCell(
                imageUrl: nil,
                header: "Connecting...",
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: "ico-empty-circle"))

        case .connected:
            let relativeTime = relativeDateFormatter.localizedString(for: session.created!, relativeTo: Date())
            let session = try! Session.from(session)
            let dappIcon = session.dAppInfo.peerMeta.icons.isEmpty ? nil : session.dAppInfo.peerMeta.icons[0]

            return tableView.detailedCell(
                imageUrl: dappIcon,
                header: session.dAppInfo.peerMeta.name,
                description: relativeTime,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: "ico-empty-circle"))
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(DesktopPairingHeaderView.self)
        view.onScan = { [unowned self] in
            self.scan()
        }
        return view
    }

    override func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        let actions = [
            UIContextualAction(style: .destructive, title: "Disconnect") { _, _, completion in
                WalletConnectKeysServerController.shared.disconnect(topic: session.topic!)
            }]
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension DesktopPairingViewController: QRCodeScannerViewControllerDelegate {
    #warning("TODO: add tracking")
    func scannerViewControllerDidScan(_ code: String) {
        do {
            try wcServerController.connect(url: code)
            dismiss(animated: true, completion: nil)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
}

extension DesktopPairingViewController: WalletConnectKeysServerControllerDelegate {
    func shouldStart(session: Session, completion: @escaping ([KeyInfo]) -> Void) {
        guard let keys = try? KeyInfo.all(), !keys.isEmpty else {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "Please import an owner key to pair with desktop")
            }
            completion([])
            return
        }
        guard keys.filter({ $0.keyType != .walletConnect}).count != 0 else {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "Connected via WalletConnect keys can not be paired with the desktop. Please import supported owner key types.")
            }
            completion([])
            return
        }

        DispatchQueue.main.async { [unowned self] in
            let vc = ConfirmConnectionViewController(dappInfo: session.dAppInfo.peerMeta)
            vc.onConnect = { [unowned vc] keys in
                vc.dismiss(animated: true) {
                    completion(keys)
                }
            }
            vc.onCancel = { [unowned vc] in
                vc.dismiss(animated: true) {
                    completion([])
                }
            }
            self.present(UINavigationController(rootViewController: vc), animated: true)
        }
    }
}
