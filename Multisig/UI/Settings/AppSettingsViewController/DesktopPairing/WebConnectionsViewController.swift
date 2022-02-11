//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class WebConnectionsViewController: UITableViewController, ExternalURLSource {
    
    @IBOutlet private var infoButton: UIBarButtonItem!

    private var connections = [CDWCConnection]()
    private let wcServerController = WalletConnectKeysServerController.shared
    private lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        url = App.configuration.help.desktopPairingURL

        title = "Connect to Web"

        wcServerController.delegate = self

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(WebConnectionTableViewCell.self)
        tableView.registerHeaderFooterView(DesktopPairingHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 98

        infoButton = UIBarButtonItem(image: UIImage(named: "ico-info-toolbar"),
                style: UIBarButtonItem.Style.plain,
                target: self,
                action: #selector(openHelpUrl))
        navigationItem.rightBarButtonItem = infoButton
        
        subscribeToNotifications()
        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.desktopPairing)
    }

    private func subscribeToNotifications() {
        [NSNotification.Name.wcConnectingKeyServer,
         .wcDidConnectKeyServer,
         .wcDidDisconnectKeyServer,
         .wcDidFailToConnectKeyServer].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(update), name: $0, object: nil)
         }
    }

    @objc private func openHelpUrl() {
        openExternalURL()
        Tracker.trackEvent(.desktopPairingLearnMore)
    }

    @objc private func update() {
       
        connections = WebConnectionProvider.allConnections()

        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    private func scan() {
        let vc = QRCodeScannerViewController()

        let string = "Go to Gnosis Safe Web and select Connect wallet." as NSString
        let textStyle = GNOTextStyle.primary.color(.white)
        let highlightStyle = textStyle.weight(.bold)
        let label = NSMutableAttributedString(string: string as String, attributes: textStyle.attributes)
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Gnosis Safe Web"))
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Connect wallet"))
        vc.attributedLabel = label

        vc.scannedValueValidator = { value in
            guard value.starts(with: "safe-wc:") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            var url = value
            url.removeFirst("safe-".count)
            return .success(url)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1//sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let connection = connections[indexPath.row]

        return tableView.webConnectionCell(
            imageName: nil,//connection.remote_icons,
            header: "Gnosis Safe",//connection.remote_name,
            connectionInfo: "gnosis-safe.io",
            connectionTimeInfo: nil,
            keyName: "my key",
            keyAddress: Address("0xbabF0d060AcF8A28dec066A16126F2566bAbdA81"),
            indexPath: indexPath,
            canSelect: false,
            placeholderImage: UIImage(named: "connection-placeholder"))

//
//        switch session.status {
//        case .connecting:
//            return tableView.detailedCell(
//                imageUrl: nil,Ï
//                header: "Connecting...",
//                description: nil,
//                indexPath: indexPath,
//                canSelect: false,
//                placeholderImage: UIImage(named: "ico-empty-circle"))
//
//        case .connected:
//            let relativeTime = relativeDateFormatter.localizedString(for: session.created!, relativeTo: Date())
//            let session = try! Session.from(session)
//            let dappIcon = session.dAppInfo.peerMeta.icons.isEmpty ? nil : session.dAppInfo.peerMeta.icons[0]
//
//            return tableView.detailedCell(
//                imageUrl: dappIcon,
//                header: session.dAppInfo.peerMeta.name,
//                description: relativeTime,
//                indexPath: indexPath,
//                canSelect: false,
//                placeholderImage: UIImage(named: "ico-empty-circle"))
//        }
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
        let connection = connections[indexPath.row]
        let actions = [
            UIContextualAction(style: .destructive, title: "Disconnect") { _, _, completion in
                //TODO: disconnect connection
                //WalletConnectKeysServerController.shared.disconnect(topic: session.topic!)
            }]
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension WebConnectionsViewController: QRCodeScannerViewControllerDelegate {
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

extension WebConnectionsViewController: WalletConnectKeysServerControllerDelegate {
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

class WebConnectionProvider {
    
    static func allConnections() -> [CDWCConnection] {
        var connections: [CDWCConnection] = []
        do {
            connections = try CDWCConnection.getAll()
        } catch {
            LogService.shared.error("Failed to get Web Connections: \(error.localizedDescription)")
        }
        return connections
    }
}
