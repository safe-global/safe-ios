//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class PairedBrowsersViewController: UITableViewController {
    private var sessions = [WCKeySession]()
    private var wcServerController = WalletConnectKeysServerController.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Paired Browsers"

        wcServerController.delegate = self

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DetailedCell.self)
        tableView.registerHeaderFooterView(PairedBrowsersHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension

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
            let session = try! Session.from(session)
            return tableView.detailedCell(
                imageUrl: nil,
                header: session.dAppInfo.peerMeta.name,
                description: session.dAppInfo.peerMeta.description,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: nil)
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(PairedBrowsersHeaderView.self)
        view.onScan = { [unowned self] in
            self.scan()
        }
        return view
    }
}

extension PairedBrowsersViewController: QRCodeScannerViewControllerDelegate {
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

extension PairedBrowsersViewController: WalletConnectKeysServerControllerDelegate {
    func shouldStart(session: Session, completion: @escaping ([KeyInfo]) -> Void) {
        guard let keys = try? KeyInfo.all() else {
            App.shared.snackbar.show(message: "Please import owner key to pair with browser")
            completion([])
            return
        }
        guard keys.filter({ $0.keyType != .walletConnect}).count != 0 else {
            App.shared.snackbar.show(message: "Connected keys can not be paired with browser. Please import supported owner key.")
            completion([])
            return
        }

        DispatchQueue.main.async { [unowned self] in
            let vc = ConfirmConnectionViewController()
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
