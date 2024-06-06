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

class AppSettingsViewController: UITableViewController, PasscodeProtecting {
    var notificationCenter = NotificationCenter.default
    var app = App.configuration.app
    var legal = App.configuration.legal

    private let tableBackgroundColor: UIColor = .backgroundPrimary
    private let sectionHeaderHeight: CGFloat = 28
    private var sections = [SectionItems]()

    private typealias SectionItems = (section: Section, items: [SectionItem])
    
    private var exportFlow: ExportDataFlow!
    private var importFlow: ImportDataFlow!

    enum Section {
        case app
        case support(String)
        case advanced(String)
        case about(String)

        enum App: SectionItem {
            case desktopPairing(String)
            case ownerKeys(String, Bool, String)
            case addressBook(String)
            case passcode(String)
            case fiat(String, String)
            case chainPrefix(String)
            case appearance(String)
            case experimental(String)
        }
        
        enum Support: SectionItem {
            case chatWithUs(String)
            case getSupport(String)
        }
        
        enum Advanced: SectionItem {
            case advanced(String)
            case toggles(String)
            case dataExport(String)
            case dataImport(String)
        }

        enum About: SectionItem {
            case aboutGnosisSafe(String)
            case appVersion(String, String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = tableBackgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }

        tableView.separatorStyle = .singleLine

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        buildSections()

        addObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsApp)
        reload()
    }

    private func buildSections() {
        sections = []
        var appSection: (section: AppSettingsViewController.Section, items: [SectionItem]) = (section: .app, items: [])
        
        if FirebaseRemoteConfig.shared.boolValue(key: .connectToWebDiscontinued) != true {
            appSection.items.append(Section.App.desktopPairing("Connect to Web"))
        }
        
        appSection.items.append(contentsOf: [
            Section.App.ownerKeys("Owner keys", !KeyInfo.keysWithoutBackup().isEmpty, "\(KeyInfo.count())"),
            Section.App.addressBook("Address Book"),
            Section.App.passcode("Security"),
            Section.App.fiat("Fiat currency", AppSettings.selectedFiatCode),
            Section.App.chainPrefix("Chain prefix"),
            Section.App.appearance("Appearance"),
            // we do not have experimental features at the moment
            //Section.App.experimental("Experimental")
        ])
        
        let supportSection: (section: AppSettingsViewController.Section, items: [SectionItem]) = (section: .support("Support & Feedback"), items: [
            Section.Support.chatWithUs("Chat with us"),
            Section.Support.getSupport("Help Center")
        ])
        var advancedSection: (section: AppSettingsViewController.Section, items: [SectionItem]) = (section: .advanced("Advanced"), items: [
            Section.Advanced.advanced("Advanced"),
            Section.Advanced.dataExport("Export data"),
            Section.Advanced.dataImport("Import data")
        ])
        
        if App.configuration.services.environment != .production {
            advancedSection.items.append(
                Section.Advanced.toggles("Feature Toggles")
            )
        }

        let aboutSection: (section: AppSettingsViewController.Section, items: [SectionItem]) = (section: .about("About"), items: [
            Section.About.aboutGnosisSafe("About Safe{Wallet}"),
            Section.About.appVersion("App version", "\(app.marketingVersion) (\(app.buildVersion))"),
        ])
        sections += [
            appSection,
            supportSection,
            advancedSection,
            aboutSection
        ]
    }

    @objc func hidePresentedController() {
        reload()
    }

    // MARK: - Actions

    @objc private func reload() {
        buildSections()
        tableView.reloadData()
    }

    private func addObservers() {
        for notification in [Notification.Name.ownerKeyRemoved,
                             .ownerKeyImported,
                             .ownerKeyBackedUp,
                             .selectedFiatCurrencyChanged,
                             .updatedExperemental,
                             .IntercomUnreadConversationCountDidChange,
                             .didReadConnectToWebBanner] {
            notificationCenter.addObserver(
                self,
                selector: #selector(reload),
                name: notification,
                object: nil)
        }
    }

    @discardableResult
    private func showDesktopPairing() -> WebConnectionsViewController? {
        if let vc = navigationTop(as: WebConnectionsViewController.self) {
            return vc
        } else {
            popNavigationStack()
        }
        
        let keys = WebConnectionController.shared.accountKeys()
        if keys.isEmpty {
            let addOwnersVC = AddOwnerFirstViewController()
            addOwnersVC.descriptionText = "To connect to Safe{Wallet} import at least one owner key. Keys are used to confirm transactions."
            addOwnersVC.onSuccess = { [weak self] in
                self?.dismiss(animated: true) {
                    _ = self?.showDesktopPairing()
                }
            }
            let nav = UINavigationController(rootViewController: addOwnersVC)
            present(nav, animated: true)
            return nil
        } else {
            let connectionsVC = WebConnectionsViewController()
            show(connectionsVC, sender: self)
            return connectionsVC
        }
    }

    private func showOwnerKeys() {
        let vc = OwnerKeysListViewController()
        show(vc, sender: self)
    }

    private func showAddressBook() {
        show(AddressBookListTableViewController(), sender: self)
    }

    private func openPasscode() {
        let vc = SecuritySettingsViewController()
        show(vc, sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    static func shouldBringAttentionToDesktopPairing() -> Bool {
        !WebConnectionController.shared.accountKeys().isEmpty &&
            AppSettings.didShowDeprecateConnectToWeb != true &&
            FirebaseRemoteConfig.shared.boolValue(key: .connectToWebDiscontinued) != true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
            
        case Section.App.desktopPairing(let name):
            return tableView.basicCell(
                name: name,
                icon: "ico-app-settings-desktop-pairing",
                indexPath: indexPath,
                supplementaryImage: Self.shouldBringAttentionToDesktopPairing() ? UIImage(named: "ico-warning") : nil)
            
        case Section.App.ownerKeys(let name, let warning, let count):
            return tableView.basicCell(name: name,
                                       icon: "ico-app-settings-key",
                                       detail: count,
                                       indexPath: indexPath,
                                       supplementaryImage: warning ? UIImage(named: "ico-private-key") : nil)

        case Section.App.addressBook(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-book", indexPath: indexPath)
            
        case Section.App.passcode(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-lock", indexPath: indexPath)
            
        case Section.App.fiat(let name, let value):
            return tableView.basicCell(name: name, icon: "ico-app-settings-fiat", detail: value, indexPath: indexPath)

        case Section.App.chainPrefix(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-hash", indexPath: indexPath)

        case Section.App.appearance(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-moon", indexPath: indexPath)
    
        case Section.App.experimental(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-package", indexPath: indexPath)
            
        case Section.Support.chatWithUs(let name):
            if IntercomConfig.unreadConversationCount() > 0 {
                return tableView.basicCell(name: name, icon: "ico-app-settings-message-circle-with-badge", indexPath: indexPath)
            } else {
                return tableView.basicCell(name: name, icon: "ico-app-settings-message-circle", indexPath: indexPath)
            }

        case Section.Support.getSupport(let name):
            return tableView.basicCell(name: name, icon: "ico-app-settings-support", indexPath: indexPath)
            
        case Section.Advanced.advanced(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
            
        case Section.Advanced.dataExport(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
            
        case Section.Advanced.dataImport(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.Advanced.toggles(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.About.aboutGnosisSafe(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
            
        case Section.About.appVersion(let name, let version):
            return tableView.infoCell(name: name, info: version, indexPath: indexPath)

        default:
            return UITableViewCell()
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.App.desktopPairing:
            showDesktopPairing()

        case Section.App.ownerKeys:
            showOwnerKeys()

        case Section.App.addressBook:
            showAddressBook()
            
        case Section.App.passcode:
            openPasscode()
            
        case Section.App.fiat:
            let selectFiatViewController = SelectFiatViewController()
            show(selectFiatViewController, sender: self)
            
        case Section.App.chainPrefix:
            show(ChainSettingsTableViewController(), sender: self)

        case Section.App.appearance:
            let appearanceViewController = ChangeDisplayModeTableViewController()
            show(appearanceViewController, sender: self)

        case Section.App.experimental:
            let experimentalViewController = ExperimentalViewController()
            show(experimentalViewController, sender: self)
            
        case Section.Support.chatWithUs:
            Tracker.trackEvent(.userOpenIntercom)
            IntercomConfig.startChat()
            break
            
        case Section.Support.getSupport:
            let getInTouchVC = GetInTouchView()
            let hostingController = UIHostingController(rootView: getInTouchVC)
            show(hostingController, sender: self)
            
        case Section.Advanced.advanced:
            navigateToAdvancedAppSettings()
            
        case Section.Advanced.dataExport:
            showExport()

        case Section.Advanced.dataImport:
            showImport()

        case Section.Advanced.toggles:
            let togglesVC = FeatureToggleTableViewController()
            show(togglesVC, sender: self)
            
        case Section.About.aboutGnosisSafe:
            show(AboutGnosisSafeTableViewController(), sender: self)
            break

        default:
            break
        }
    }
    
    private func showExport() {
        authenticate(biometry: false) { [weak self] success in
            guard success, let self = self else { return }
            
            self.exportFlow = ExportDataFlow(completion: { [weak self] success in
                self?.exportFlow = nil
            })
            self.present(flow: self.exportFlow, dismissableOnSwipe: false)
        }
    }
    
    private func showImport() {
        authenticate(biometry: false) { [weak self] success in
            guard success, let self = self else { return }
            
            self.importFlow = ImportDataFlow(completion: { [weak self] success in
                self?.importFlow = nil
            })
            self.present(flow: self.importFlow, dismissableOnSwipe: false)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = sections[section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.support(let name):
            view.setName(name)
            
        case Section.advanced(let name):
            view.setName(name)
            
        case Section.about(let name):
            view.setName(name)
            
        default:
            break
        }
        
        return view
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return BasicCell.rowHeight
    }
  
    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        switch section {
        case .app:
            return 0
        default:
            return BasicHeaderView.headerHeight
        }
    }
}

extension AppSettingsViewController: NavigationRouter {
    func routeFrom(from url: URL) -> NavigationRoute? {
        nil
    }
    
    func canNavigate(to route: NavigationRoute) -> Bool {
        if route.path == NavigationRoute.connectToWeb().path && FirebaseRemoteConfig.shared.boolValue(key: .connectToWebDiscontinued) != true {
            return true
        }
        return false
    }

    func navigate(to route: NavigationRoute) {
        if route.path == NavigationRoute.appearanceSettings().path {
            navigateToAppearance()
        } else if route.path == NavigationRoute.connectToWeb().path && FirebaseRemoteConfig.shared.boolValue(key: .connectToWebDiscontinued) != true {
            navigateToConnectToWeb(route)
        } else if route.path == NavigationRoute.advancedAppSettings().path {
            navigateToAdvancedAppSettings()
        } else if route.path == NavigationRoute.addressBook().path {
            navigateToAddressBook()
        } else if NavigationRoute.appSettingsAboutPaths.contains(route.path) {
            navigateToAbout(route)
        }
    }
    
    private func navigateToAbout(_ route: NavigationRoute) {
        var aboutVC: AboutGnosisSafeTableViewController
        if let vc = navigationTop(as: AboutGnosisSafeTableViewController.self) {
            aboutVC = vc
        } else {
            popNavigationStack()
            
            aboutVC = AboutGnosisSafeTableViewController()
            show(aboutVC, sender: self)
        }

        aboutVC.navigateAfterDelay(to: route)
    }
    
    private func navigateToAppearance() {
        if navigationTopIs(ChangeDisplayModeTableViewController.self) {
            return
        }
        
        popNavigationStack()
        
        let appearanceViewController = ChangeDisplayModeTableViewController()
        show(appearanceViewController, sender: self)
    }
    
    private func navigateToConnectToWeb(_ route: NavigationRoute) {
        guard FirebaseRemoteConfig.shared.boolValue(key: .connectToWebDiscontinued) != true else { return }
        if let pairingVC = showDesktopPairing() {
            pairingVC.navigateAfterDelay(to: route)
        }
    }
    
    private func navigateToAdvancedAppSettings() {
        if navigationTopIs(UIHostingController<AdvancedAppSettings>.self) {
            return
        }

        popNavigationStack()
        
        let advancedVC = AdvancedAppSettings()
        let hostingController = UIHostingController(rootView: advancedVC)
        show(hostingController, sender: self)
    }
    
    private func navigateToAddressBook() {
        if navigationTopIs(AddressBookListTableViewController.self) {
            return
        }
        
        popNavigationStack()
        
        showAddressBook()
    }
}
