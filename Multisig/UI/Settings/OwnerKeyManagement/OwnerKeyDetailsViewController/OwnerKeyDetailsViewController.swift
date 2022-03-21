//
//  OwnerKeyDetailsViewController.swift
//  Multisig
//
//  Created by Moaaz on 5/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

fileprivate protocol SectionItem {}

class OwnerKeyDetailsViewController: UITableViewController {
    // if not nil, then back button replaced with 'Done' button
    private var completion: (() -> Void)?

    private var walletPerTopic = [String: InstalledWallet]()
    private var waitingForSession = false
    
    private var keyInfo: KeyInfo!
    private var exportButton: UIBarButtonItem!
    let tableBackgroundColor: UIColor = .primaryBackground

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()
    private var addKeyController: DelegateKeyController!

    private var connection: WebConnection!

    enum Section {
        case name(String)
        case keyAddress(String)
        case ownerKeyType(String)
        case connected(String)
        case pushNotificationConfiguration(String)
        case delegateKey(String)
        case advanced

        enum Name: SectionItem {
            case name
        }

        enum KeyAddress: SectionItem {
            case address
        }

        enum OwnerKeyType: SectionItem {
            case type
        }

        enum Connected: SectionItem {
            case connected
        }

        enum PushNotificationConfiguration: SectionItem {
            case enabled
        }

        enum DelegateKey: SectionItem {
            case address
            case helpLink
        }

        enum Advanced: SectionItem {
            case remove
        }
    }

    convenience init(keyInfo: KeyInfo, completion: (() -> Void)? = nil) {
        self.init()
        self.keyInfo = keyInfo
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(keyInfo != nil, "Developer error: expect to have a key")

        navigationItem.title = "Owner Key"

        if [KeyType.deviceImported, .deviceGenerated].contains(keyInfo.keyType) {
            exportButton = UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(didTapExportButton))
            navigationItem.rightBarButtonItem = exportButton
        }

        if completion != nil {
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pop))
            navigationItem.leftBarButtonItem = doneButton
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = tableBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(KeyTypeTableViewCell.self)
        tableView.registerCell(RemoveCell.self)
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.registerCell(HelpLinkTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        for notification in [Notification.Name.ownerKeyUpdated] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(reloadData),
                name: notification,
                object: nil)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pop),
            name: .ownerKeyRemoved,
            object: nil)

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerKeyDetails)
    }

    @IBAction func removeButtonTouched(_ sender: Any) {
        removeKey()
    }

    @objc private func didTapExportButton() {
        let exportViewController = ExportViewController()

        do {
            if let privateKey = try keyInfo.privateKey() {
                exportViewController.privateKey = privateKey.keyData.toHexStringWithPrefix()
                exportViewController.seedPhrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) }
            } else {
                App.shared.snackbar.show(error: GSError.PrivateKeyDataNotFound(reason: "Key data does not exist"))
                return
            }
        } catch {
            App.shared.snackbar.show(error: GSError.PrivateKeyFetchError(reason: error.localizedDescription))
            return
        }

        if App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForExportingKeys) {
            let vc = EnterPasscodeViewController()
            vc.passcodeCompletion = { [weak self] success, _ in
                guard let `self` = self else { return }
                self.dismiss(animated: true) {
                    if success {
                        self.show(exportViewController, sender: self)
                    }
                }
            }

            present(vc, animated: true, completion: nil)
        } else {
            show(exportViewController, sender: self)
        }
    }

    @objc private func reloadData() {
        DispatchQueue.main.async { [unowned self] in
            // it may happen that key info is updated in the CoreData but the current managed object
            // that we retained here is not updated.
            if let key = keyInfo {
                keyInfo = try? KeyInfo.firstKey(address: key.address)
            }

            self.sections = [
                (section: .name("OWNER NAME"), items: [Section.Name.name]),

                (section: .keyAddress("OWNER ADDRESS"),
                        items: [Section.KeyAddress.address]),

                (section: .ownerKeyType("OWNER TYPE"),
                        items: [Section.OwnerKeyType.type])]

            if self.keyInfo.keyType == .walletConnect {
                self.sections.append((section: .connected("WC CONNECTION"), items: [Section.Connected.connected]))
            }

            if [.walletConnect, .ledgerNanoX].contains(keyInfo.keyType) {
                self.sections.append((section: .pushNotificationConfiguration("PUSH NOTIFICATIONS"),
                        items: [Section.PushNotificationConfiguration.enabled]))
                if self.keyInfo.delegateAddress != nil {
                    self.sections.append((section: .delegateKey("DELEGATE KEY ADDRESS"),
                            items: [Section.DelegateKey.address, Section.DelegateKey.helpLink]))
                }
            }

            self.sections.append((section: .advanced, items: [Section.Advanced.remove]))

            self.tableView.reloadData()
        }
    }

    @objc private func pop() {
        navigationController?.popViewController(animated: true)
        completion?()
    }

    private func removeKey() {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            OwnerKeyController.remove(keyInfo: self.keyInfo)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    private func showConnectionQRCodeController() {
        WalletConnectClientController.showConnectionQRCodeController(from: self) { result in
            switch result {
            case .success(_):
                waitingForSession = true
            case .failure(let error):
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not create connection URL", error: error))
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name:
            return tableView.basicCell(name: keyInfo.name ?? "", indexPath: indexPath)
        case Section.KeyAddress.address:
            return tableView.addressDetailsCell(address: keyInfo.address, showQRCode: true, indexPath: indexPath)
        case Section.OwnerKeyType.type:
            return keyTypeCell(type: keyInfo.keyType, indexPath: indexPath)
        case Section.Connected.connected:
            return tableView.switchCell(for: indexPath,
                                           with: "Connected",
                                           isOn: keyInfo.connected)
        case Section.PushNotificationConfiguration.enabled:
            return tableView.switchCell(for: indexPath, with: "Receive Push Notifications", isOn: keyInfo.delegateAddress != nil)
        case Section.DelegateKey.address:
            return tableView.addressDetailsCell(address: keyInfo.delegateAddress ?? Address.zero, indexPath: indexPath)
        case Section.DelegateKey.helpLink:
            return tableView.helpLinkCell(text: "What is a delegate key and how does it relate to the Gnosis Safe",
                                url: App.configuration.help.delegateKeyURL,
                                indexPath: indexPath)
        case Section.Advanced.remove:
            return tableView.removeCell(indexPath: indexPath, title: "Remove owner key") { [weak self] in
                self?.removeKey()
            }
        default:
            return UITableViewCell()
        }
    }

    private func keyTypeCell(type: KeyType, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(KeyTypeTableViewCell.self, for: indexPath)
        cell.set(name: type.name, iconName: type.imageName)
        if !(type == .walletConnect && keyInfo.connected) {
            cell.setDisclosureImage(nil)
        } else {
            cell.setDisclosureImage(UIImage(named: "arrow"))
        }
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name:
            let vc = EditOwnerKeyViewController(keyInfo: keyInfo)
            show(vc, sender: self)
        case Section.Connected.connected:
            if keyInfo.connected {
                let alertController = DisconnectionConfirmationController.create(key: keyInfo)
                present(alertController, animated: true)
            } else {
                // try to reconnect
                if let _ = keyInfo.wallet {
                    self.connect(keyInfo: keyInfo)
                } else {
                    self.showConnectionQRCodeController()
                }
            }
        case Section.PushNotificationConfiguration.enabled:
            do {
                addKeyController = try DelegateKeyController(ownerAddress: keyInfo.address) {
                    self.dismiss(animated: true, completion: nil)
                }
                addKeyController.presenter = self
                if keyInfo.delegateAddress == nil {
                    addKeyController.createDelegate()
                } else {
                    addKeyController.deleteDelegate()
                }
            } catch {
                App.shared.snackbar.show(message: error.localizedDescription)
            }
            return
        case Section.OwnerKeyType.type:
            if keyInfo.keyType == .walletConnect && keyInfo.connected {
                let detailsVC = WebConnectionDetailsViewController()
                guard let webConnection = WebConnectionController.shared.walletConnection(keyInfo: keyInfo).first else {
                    return
                }
                detailsVC.connection = webConnection
                let vc = ViewControllerFactory.modal(viewController: detailsVC)
                present(vc, animated: true)
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.KeyAddress.address:
            return UITableView.automaticDimension
        case Section.DelegateKey.address:
            return UITableView.automaticDimension
        case Section.DelegateKey.helpLink:
            return UITableView.automaticDimension
        case Section.Advanced.remove:
            return RemoveCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.name(let name):
            view.setName(name)
        case Section.keyAddress(let name):
            view.setName(name)
        case Section.ownerKeyType(let name):
            view.setName(name)
        case Section.connected(let name):
            view.setName(name)
        case .pushNotificationConfiguration(let name):
            view.setName(name)
        case .delegateKey(let name):
            view.setName(name)
        case Section.advanced:
            break
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        if case Section.advanced = section {
            return 0
        }

        return BasicHeaderView.headerHeight
    }

    //TODO remove duplication
    func connect(keyInfo: KeyInfo) {
        guard let wallet = keyInfo.wallet, let wcWallet = WCAppRegistryRepository().entry(from: wallet) else {
            return
        }

        let chain = Selection.current().safe?.chain ?? Chain.mainnetChain()

        let walletConnectionVC = StartWalletConnectionViewController(wallet: wcWallet, chain: chain)
        walletConnectionVC.onSuccess = { [weak walletConnectionVC] connection in
            walletConnectionVC?.dismiss(animated: true) {
                guard connection.accounts.contains(keyInfo.address) else {
                    App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
                    return
                }

                if OwnerKeyController.updateKey(connection: connection, wallet: wcWallet) {
                    App.shared.snackbar.show(message: "Key connected successfully")
                }
            }
        }
        walletConnectionVC.onCancel = { [weak walletConnectionVC] in
            walletConnectionVC?.dismiss(animated: true, completion: nil)
        }
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: true)
        present(vc, animated: true)
    }
}

extension KeyType {
    var name: String {
        switch self {
        case .deviceGenerated:
            return "Generated"
        case .deviceImported:
            return "Imported"
        case .ledgerNanoX:
            return "Ledger Nano X"
        case .walletConnect:
            return "WalletConnect"
        }
    }
}

