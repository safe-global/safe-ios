//
//  AppSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 10.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

fileprivate protocol SectionItem {}

class AppSettingsViewController: UITableViewController {
    let app = App.configuration.app
    let tableBackgroundColor: UIColor = .gnoWhite
    let advancedSectionHeaderHeight: CGFloat = 28
    var notificationCenter = NotificationCenter.default

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    enum Section {
        case general
        case advanced

        enum General: SectionItem {
            case importKey(String)
            case importedKey(String, String)
            case terms(String)
            case appVersion(String, String)
            case network(String, String)
        }

        enum Advanced: SectionItem {
            case advanced(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = tableBackgroundColor
        tableView.separatorStyle = .none
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(ImportedKeyCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        buildSections()

        notificationCenter.addObserver(
            self, selector: #selector(hidePresentedController), name: .ownerKeyImported, object: nil)
    }

    private func buildSections() {
        let signingKey = AppSettings.current().signingKeyAddress
        sections = [
            (section: .general, items: [
                signingKey != nil ?
                    Section.General.importedKey("Imported owner key", signingKey!) :
                    Section.General.importKey("Import owner key"),
                Section.General.appVersion("App version", app.marketingVersion),
                Section.General.network("Network", app.network.rawValue),
            ]),
            (section: .advanced, items: [Section.Advanced.advanced("Advanced")])
        ]
    }

    @objc func hidePresentedController() {
        presentedViewController?.dismiss(animated: true)
        reload()
    }

    private func reload() {
        buildSections()
        tableView.reloadData()
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
        case Section.General.importKey(let name):
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        case Section.General.importedKey(let name, let signingKey):
            let cell = tableView.dequeueCell(ImportedKeyCell.self, for: indexPath)
            cell.setName(name)
            cell.setAddress(Address(exactly: signingKey))
            cell.selectionStyle = .none
            cell.onRemove = { [unowned self] in
                self.removeImportedOwnerKey()
            }
            return cell
        case Section.General.appVersion(let name, let version):
            let cell = tableView.dequeueCell(InfoCell.self, for: indexPath)
            cell.setTitle(name)
            cell.setInfo(version)
            cell.selectionStyle = .none
            return cell
        case Section.General.network(let name, let network):
            let cell = tableView.dequeueCell(InfoCell.self, for: indexPath)
            cell.setTitle(name)
            cell.setInfo(network)
            cell.selectionStyle = .none
            return cell
        case Section.Advanced.advanced(let name):
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        default:
            return UITableViewCell()
        }
    }

    #warning("TODO: show snackbar message")
    private func removeImportedOwnerKey() {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn't delete any Safes from this app or from blockchain. For Safes controlled by this owner key, you will no longer be able to sign transactions in this app",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
            do {
                try App.shared.keychainService.removeData(
                    forKey: KeychainKey.ownerPrivateKey.rawValue)
                AppSettings.setSigningKeyAddress(nil)
//                App.shared.snackbar.show(message: "Owner key removed from this app")
                Tracker.shared.setUserProperty("0", for: TrackingUserProperty.numKeysImported)
                self.reload()
            } catch {
                LogService.shared.error(error.localizedDescription)
                App.shared.snackbar.show(message: error.localizedDescription)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.General.importKey(_):
            let enterSeedVC = EnterSeedPhraseView().hostSnackbar()
            let hostingController = UIHostingController(rootView: enterSeedVC)
            present(hostingController, animated: true)
        case Section.Advanced.advanced(_):
            let advancedVC = AdvancedAppSettings()
            let hostingController = UIHostingController(rootView: advancedVC)
            show(hostingController, sender: self)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName("")
        return view
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.General.appVersion(_, _), Section.General.network(_, _):
            return InfoCell.rowHeight
        default:
            return BasicCell.rowHeight
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        if case Section.advanced = section {
            return advancedSectionHeaderHeight
        }
        return 0
    }
}
