//
//  DappsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import WalletConnectSign

fileprivate protocol SectionItem {}

class DappsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var wcButton: UIButton!

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    private var showedNotificationsSessionTopics = [String]()

    enum Section {
        case walletConnect(String)
        case dapp(String)

        enum WalletConnect: SectionItem {
            case activeSession(Any)
            case noSessions(String)
        }

        enum Dapp: SectionItem {
            case dapp(DappData)
        }
    }

    @IBAction func scan(_ sender: Any) {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { value in
            guard (value.starts(with: "wc:") || value.starts(with: "safe-wc:")) else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        subscribeToNotifications()
        
        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.dapps)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .backgroundPrimary
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerHeaderFooterView(ExternalLinkHeaderFooterView.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailedCell.self)
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = BasicHeaderView.headerHeight
        tableView.estimatedRowHeight = DetailedCell.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }

    @objc private func update() {
        DispatchQueue.main.async { [unowned self] in
            var wcSessionItems: [SectionItem] = []
            do {
                if let selectedSafe = try? Safe.getSelected() {
                    wcSessionItems = try WCSession.getAll().compactMap {
                        guard $0.session != nil,
                              let session = try? Session.from($0),
                              session.walletInfo!.accounts.contains(selectedSafe.address!) else {
                            return nil
                        }

                        return Section.WalletConnect.activeSession($0)
                    }

                    let walletConnectV2Sessions = WalletConnectManager.shared.getSessions(topics: selectedSafe.walletConnectSessiontopics)

                    wcSessionItems.append(contentsOf: walletConnectV2Sessions.compactMap {
                        return Section.WalletConnect.activeSession($0)
                    })
                }

                if wcSessionItems.isEmpty {
                    wcSessionItems.append(Section.WalletConnect.noSessions("No active sessions"))
                }
            } catch {
                wcSessionItems = [Section.WalletConnect.noSessions("No active sessions")]
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not load WalletConnect sessions", error: error))
            }

            sections = [
                (section: .walletConnect("WalletConnect"), items: wcSessionItems)
            ]

            let dappSectionItems = DappsDataSource().dapps.map { Section.Dapp.dapp($0) }
            if !dappSectionItems.isEmpty {
                sections.append((section: .dapp("Dapps supporting Safe"), items: dappSectionItems))
            }
            self.tableView.reloadData()
        }
    }

    private func subscribeToNotifications() {
        [NSNotification.Name.wcConnectingSafeServer,
         .wcDidConnectSafeServer,
         .wcDidDisconnectSafeServer,
         .wcDidFailToConnectSafeServer,
         .selectedSafeChanged].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(update), name: $0, object: nil)
         }

        NotificationCenter.default.addObserver(forName: .wcDidConnectSafeServer, object: nil, queue: nil) {
            [weak self] notification in

            guard let self = self, let topic = notification.userInfo?["topic"] as? String else { return }

            // skip snackbar notification for reconnect cases
            if !self.showedNotificationsSessionTopics.contains(topic) {
                self.showedNotificationsSessionTopics.append(topic)
                DispatchQueue.main.async {
                    App.shared.snackbar.show(message: "WalletConnect session created! Please return back to the browser.")
                }
            }
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case Section.WalletConnect.noSessions(let name):
            return tableView.basicCell(
                name: name, indexPath: indexPath, disclosureImage: nil, canSelect: false)

        case Section.WalletConnect.activeSession(let wcSession):
            if let v1Session = wcSession as? WCSession {
                switch v1Session.status {
                case .connecting:
                    return tableView.detailedCell(
                        imageUrl: nil,
                        header: "Connecting...",
                        description: nil,
                        indexPath: indexPath,
                        canSelect: false,
                        placeholderImage: UIImage(named: "ico-empty-circle"))
                case .connected:
                    let session = try! Session.from(v1Session)
                    return tableView.detailedCell(
                        imageUrl: session.dAppInfo.peerMeta.icons.isEmpty ? nil : session.dAppInfo.peerMeta.icons[0],
                        header: session.dAppInfo.peerMeta.name,
                        description: session.dAppInfo.peerMeta.description,
                        indexPath: indexPath,
                        canSelect: false,
                        placeholderImage: #imageLiteral(resourceName: "ico-empty-circle"))
                }
            } else if let v2Session = wcSession as? WalletConnectSign.Session {
                return tableView.detailedCell(
                    imageUrl: v2Session.peer.icons.isEmpty ? nil : URL(string: v2Session.peer.icons[0]),
                    header: v2Session.peer.name,
                    description: v2Session.peer.description,
                    indexPath: indexPath,
                    canSelect: false,
                    placeholderImage: #imageLiteral(resourceName: "ico-empty-circle"))
            } else {
                return UITableViewCell()
            }
        case Section.Dapp.dapp(let dapp):
            return tableView.detailedCell(
                imageUrl: dapp.logo,
                header: dapp.name,
                description: dapp.description,
                indexPath: indexPath,
                placeholderImage: #imageLiteral(resourceName: "ico-empty-circle"))

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = sections[indexPath.section].items[indexPath.row]
        if case Section.WalletConnect.activeSession(_) = item {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]

        if case Section.WalletConnect.activeSession(let session) = item {
            if let v1Session = session as? WCSession {
                WalletConnectSafesServerController.shared.disconnect(topic: v1Session.topic!)
            } else if let v2Session = session as? WalletConnectSign.Session {
                WalletConnectManager.shared.disconnect(session: v2Session)
            }
        }
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        if case Section.Dapp.dapp(let dapp) = item {
            UIApplication.shared.open(dapp.url)
            Tracker.trackEvent(.selectDapp, parameters: ["dapp_name" : dapp.name.prefix(100)])
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
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

    func tableView(_ tableView: UITableView, viewForFooterInSection _section: Int) -> UIView? {
        guard case Section.walletConnect(_) = sections[_section].section else {
            return nil
        }
        let view = tableView.dequeueHeaderFooterView(ExternalLinkHeaderFooterView.self)
        view.set(label: "How to connect a dapp via WalletConnect on Safe{Wallet} Mobile?")
        view.set(url: App.configuration.help.connectDappOnMobileURL)
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection _section: Int) -> CGFloat {
        guard case Section.walletConnect(_) = sections[_section].section else {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Disconnect"
    }
}

extension DappsViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ url: String) {
        if (url.starts(with: "safe-wc:")) {
            dismiss(animated: true) {
                let route = NavigationRoute.connectToWeb(url)
                CompositeNavigationRouter.shared.navigate(to: route)
            }
        } else {
            if WalletConnectManager.shared.canConnect(url: url) {
                WalletConnectManager.shared.pairClient(url: url, trackingEvent: .dappConnectedWithScanButton)
                dismiss(animated: true, completion: nil)
            } else {
                do {
                    try WalletConnectSafesServerController.shared.connect(url: url)
                    WalletConnectSafesServerController.shared.dappConnectedTrackingEvent = .dappConnectedWithScanButton
                    dismiss(animated: true, completion: nil)
                } catch {
                    App.shared.snackbar.show(message: error.localizedDescription)
                }
            }
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
}
