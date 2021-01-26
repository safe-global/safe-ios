//
//  DappsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

fileprivate protocol SectionItem {}

class DappsViewController: UITableViewController {
    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    enum Section {
        case walletConnect(String)
        case dapp(String)

        enum WalletConnect: SectionItem {
            case activeSession(WCSession)
            case noSessions(String)
        }

        enum Dapp: SectionItem {
            case name(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        addWCButton()
        subscribeToWCNotifications()
        
        update()
    }

    private func configureTableView() {
        tableView.backgroundColor = .gnoWhite
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailedCell.self)
    }

    private func addWCButton() {
        let button = UIButton()
        button.setImage(UIImage(named: "wc-button"), for: .normal)
        button.addTarget(self, action: #selector(scan), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func update() {
        var sessionItems: [SectionItem]
        do {
            sessionItems = try WCSession.getAll().compactMap {
                Section.WalletConnect.activeSession($0)
            }
            if sessionItems.isEmpty {
                sessionItems.append(Section.WalletConnect.noSessions("No active sessions"))
            }
        } catch {
            sessionItems = [Section.WalletConnect.noSessions("No active sessions")]
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not load WalletConnect sessions", error: error))
        }

        sections = [
            (section: .walletConnect("WalletConnect"), items: sessionItems)
        ]

        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    private func subscribeToWCNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(wcNotificationReceived), name: .wcConnecting, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(wcNotificationReceived), name: .wcDidConnect, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(wcNotificationReceived), name: .wcDidDisconnect, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(wcNotificationReceived), name: .wcDidFailToConnect, object: nil)
    }

    @objc private func scan() {
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

    @objc private func wcNotificationReceived() {
        update()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case Section.WalletConnect.noSessions(let name):
            return tableView.basicCell(
                name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        case Section.WalletConnect.activeSession(let wcSession):
            switch wcSession.status {
            case .connecting:
                return tableView.detailedCell(
                    imageUrl: nil,
                    header: "Connecting...",
                    description: nil,
                    indexPath: indexPath,
                    canSelect: false,
                    placeholderImage: #imageLiteral(resourceName: "ico-empty-circle"))
            case .connected:
                let session = try! Session.from(wcSession)
                return tableView.detailedCell(
                    imageUrl: session.dAppInfo.peerMeta.icons.isEmpty ? nil : session.dAppInfo.peerMeta.icons[0],
                    header: session.dAppInfo.peerMeta.name,
                    description: session.dAppInfo.peerMeta.description,
                    indexPath: indexPath,
                    canSelect: false,
                    placeholderImage: #imageLiteral(resourceName: "ico-empty-circle"))
            }

        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section].section

        switch section {
        case Section.walletConnect(_):
            return true

        default:
            return false
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]

        if case Section.WalletConnect.activeSession(let session) = item {
            WalletConnectController.shared.disconnect(topic: session.topic!)
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.walletConnect(let name):
            view.setName(name)

        case Section.dapp(let name):
            view.setName(name)
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DetailedCell.rowHeight
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Disconnect"
    }
}

extension DappsViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ code: String) {
        do {
            try WalletConnectController.shared.connect(url: code)
            dismiss(animated: true, completion: nil)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
}
