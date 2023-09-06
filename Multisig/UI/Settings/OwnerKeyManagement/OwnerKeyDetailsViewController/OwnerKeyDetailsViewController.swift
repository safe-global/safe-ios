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

class OwnerKeyDetailsViewController: UITableViewController, WebConnectionObserver, PasscodeProtecting {
    // if not nil, then back button replaced with 'Done' button
    private var completion: (() -> Void)?
    
    private var keyInfo: KeyInfo!
    private var exportButton: UIBarButtonItem!
    let tableBackgroundColor: UIColor = .backgroundPrimary

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()
    private var addKeyController: DelegateKeyController!

    private var connection: WebConnection?

    private var backupFlow: ModalBackupFlow!

    enum Section {
        case backedup
        case name(String)
        case email(String)
        case keyAddress(String)
        case ownerKeyType(String)
        case connected(String)
        case pushNotificationConfiguration(String)
        case delegateKey(String)
        case advanced

        enum Backedup: SectionItem {
            case backedup
        }

        enum Name: SectionItem {
            case name
        }

        enum Email: SectionItem {
            case email
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

        if KeyType.privateKeyTypes.contains(keyInfo.keyType) {
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

        tableView.registerCell(BackupKeyTableViewCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(KeyTypeTableViewCell.self)
        tableView.registerCell(RemoveCell.self)
        tableView.registerCell(SwitchTableViewCell.self)
        tableView.registerCell(HelpLinkTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        for notification in [Notification.Name.ownerKeyUpdated,
                             .ownerKeyBackedUp] {
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

        connection = WebConnectionController.shared.walletConnection(keyInfo: keyInfo).first

        if let connection = connection {
            WebConnectionController.shared.attach(observer: self, to: connection)
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerKeyDetails)
    }

    @IBAction func removeButtonTouched(_ sender: UIButton) {
        removeKey()
    }

    @objc private func didTapExportButton() {
        let exportViewController = ExportViewController()

        if AppConfiguration.FeatureToggles.securityCenter {

            keyInfo.privateKey { [unowned self] result in
                do {
                    if let privateKey = try result.get() {
                        exportViewController.privateKey = privateKey.keyData.toHexStringWithPrefix()
                        exportViewController.seedPhrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) }
                        self.show(exportViewController, sender: self)
                    } else {
                        App.shared.snackbar.show(error: GSError.PrivateKeyDataNotFound(reason: "Key data does not exist"))
                        return
                    }
                } catch let userCancellationError as GSError.CancelledByUser {
                    return
                } catch {
                    App.shared.snackbar.show(error: GSError.PrivateKeyFetchError(reason: error.localizedDescription))
                    return
                }
            }

        } else {

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

            authenticate(biometry: false) { [unowned self] success in
                if success {
                    show(exportViewController, sender: self)
                }
            }
        }
    }

    @objc private func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.doReloadData()
        }
    }

    private func doReloadData() {
        // it may happen that key info is updated in the CoreData but the current managed object
        // that we retained here is not updated.
        if let key = keyInfo {
            keyInfo = try? KeyInfo.firstKey(address: key.address)
        }
        
        guard let keyInfo = keyInfo else {
            return
        }

        sections = [
            (section: .name("OWNER NAME"), items: [Section.Name.name])]

        if KeyType.socialKeyTypes.contains(keyInfo.keyType) {
            sections.append((section: .email("EMAIL ADDRESS"), items: [Section.Email.email]))
        }

        sections.append(contentsOf: [(section: .keyAddress("OWNER ADDRESS"), items: [Section.KeyAddress.address]),
                                     (section: .ownerKeyType("OWNER TYPE"), items: [Section.OwnerKeyType.type])])

        if keyInfo.keyType == .walletConnect {
            sections.append((section: .connected("WC CONNECTION"), items: [Section.Connected.connected]))
        }

        sections.append((section: .pushNotificationConfiguration("PUSH NOTIFICATIONS"),
                         items: [Section.PushNotificationConfiguration.enabled]))

        if keyInfo.delegateAddress != nil {
            sections.append((section: .delegateKey("DELEGATE KEY ADDRESS"),
                    items: [Section.DelegateKey.address, Section.DelegateKey.helpLink]))
        }

        sections.append((section: .advanced, items: [Section.Advanced.remove]))

        if keyInfo.needsBackup {
            sections.insert((section: .backedup, items: [Section.Backedup.backedup]), at: 0)
        }

        tableView.reloadData()
    }

    @objc private func pop() {
        navigationController?.popViewController(animated: true)
        completion?()
    }

    private func removeKey() {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .multiplatformActionSheet)

        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            OwnerKeyController.remove(keyInfo: self.keyInfo)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
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
        case Section.Backedup.backedup:
            return tableView.backupKeyCell(indexPath: indexPath) { [weak self] in
                self?.startBackup()
            }
        case Section.Name.name:
            return tableView.basicCell(name: keyInfo.displayName, indexPath: indexPath)
        case Section.Email.email:
            let nameCell = tableView.basicCell(name: keyInfo.email ?? "", indexPath: indexPath, disclosureImage: nil)
            nameCell.selectionStyle = .none
            return nameCell
        case Section.KeyAddress.address:
            return tableView.addressDetailsCell(address: keyInfo.address, showQRCode: true, indexPath: indexPath)
        case Section.OwnerKeyType.type:
            return keyTypeCell(type: keyInfo.keyType, indexPath: indexPath)
        case Section.Connected.connected:
            return tableView.switchCell(for: indexPath,
                                           with: "Connected",
                                           isOn: keyInfo.connectedAsDapp)
        case Section.PushNotificationConfiguration.enabled:
            return tableView.switchCell(for: indexPath, with: "Receive Push Notifications", isOn: keyInfo.delegateAddress != nil)
        case Section.DelegateKey.address:
            return tableView.addressDetailsCell(address: keyInfo.delegateAddress ?? Address.zero, indexPath: indexPath)
        case Section.DelegateKey.helpLink:
            return tableView.helpLinkCell(text: "What is a delegate key and how does it relate to the Safe Account",
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

    private func startBackup() {
        Tracker.trackEvent(.backupFromKeyDetails)

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

    private func keyTypeCell(type: KeyType, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(KeyTypeTableViewCell.self, for: indexPath)
        cell.set(name: type.name, iconName: type.badgeName)
        if !(type == .walletConnect && keyInfo.connectedAsDapp) {
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
            if keyInfo.connectedAsDapp {
                let alertController = DisconnectionConfirmationController.create(key: keyInfo)
                present(alertController, animated: true)
            } else {
                self.connect(keyInfo: keyInfo)
            }
        case Section.PushNotificationConfiguration.enabled:
            if AppConfiguration.FeatureToggles.securityCenter {
                do {
                    self.addKeyController = try DelegateKeyController(ownerAddress: self.keyInfo.address) { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                    self.addKeyController.presenter = self
                    if self.keyInfo.delegateAddress == nil {
                        self.addKeyController.createDelegate()
                    } else {
                        self.addKeyController.deleteDelegate()
                    }
                } catch {
                    App.shared.snackbar.show(message: error.localizedDescription)
                }
            } else {
                authenticate(options: [.useForConfirmation]) { [weak self] success in
                    guard let self = self else { return }

                    if success {
                        do {
                            self.addKeyController = try DelegateKeyController(ownerAddress: self.keyInfo.address) { [weak self] in
                                self?.dismiss(animated: true, completion: nil)
                            }
                            self.addKeyController.presenter = self
                            if self.keyInfo.delegateAddress == nil {
                                self.addKeyController.createDelegate()
                            } else {
                                self.addKeyController.deleteDelegate()
                            }
                        } catch {
                            App.shared.snackbar.show(message: error.localizedDescription)
                        }
                    }
                }
            }
        case Section.OwnerKeyType.type:
            if keyInfo.keyType == .walletConnect && keyInfo.connectedAsDapp {
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
        case Section.Backedup.backedup:
            return UITableView.automaticDimension
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
        case Section.email(let name):
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
        default:
            return nil
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        if case Section.advanced = section {
            return 0
        } else if case Section.backedup = section {
            return 0
        }

        return BasicHeaderView.headerHeight
    }

    //TODO remove duplication
    func connect(keyInfo: KeyInfo) {
        let wcWallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        let chain = Selection.current().safe?.chain ?? Chain.mainnetChain()
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wcWallet, chain: chain, keyInfo: keyInfo)
        walletConnectionVC.onSuccess = { [weak self] connection in
            guard let self = self else { return }
            self.connection = connection
            WebConnectionController.shared.attach(observer: self, to: connection)
        }
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: wcWallet != nil)
        present(vc, animated: true)
    }

    func didUpdate(connection: WebConnection) {
        self.connection = connection
        if connection.status == .final {
            self.connection = nil
            WebConnectionController.shared.detach(observer: self)
        }
        reloadData()
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }
}
extension UITableView {
    func backupKeyCell(indexPath: IndexPath, onClick: (() -> ())? = nil) -> BackupKeyTableViewCell {
        let cell = dequeueCell(BackupKeyTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none

        cell.onClick = onClick

        return cell
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
        case .keystone:
            return "Keystone"
        case .web3AuthApple:
            return "Social Key"
        case .web3AuthGoogle:
            return "Social Key"
        }
    }
}

extension KeyInfo {
    var email: String? {
        if KeyType.socialKeyTypes.contains(keyType), let metadata = metadata {
            return try! JSONDecoder().decode(String.self, from: metadata)
        }

        return nil
    }
}

