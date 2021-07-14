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
    var notificationCenter = NotificationCenter.default
    var app = App.configuration.app
    var legal = App.configuration.legal

    private let tableBackgroundColor: UIColor = .primaryBackground
    private let sectionHeaderHeight: CGFloat = 28
    private var sections = [SectionItems]()

    private typealias SectionItems = (section: Section, items: [SectionItem])

    enum Section {
        case app
        case general
        case advanced

        enum App: SectionItem {
            case ownerKeys(String, String)
            case passcode(String)
            case appearance(String)
            case fiat(String, String)
            case experimental(String)
        }

        enum General: SectionItem {
            case terms(String)
            case privacyPolicy(String)
            case licenses(String)
            case getInTouch(String)
            case rateTheApp(String)
            case appVersion(String, String)
        }

        enum Advanced: SectionItem {
            case advanced(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = tableBackgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
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
    }

    private func buildSections() {
        sections = [
            (section: .app, items: [
                Section.App.ownerKeys("Owner keys", "\(KeyInfo.count())"),
                Section.App.passcode("Passcode"),
                Section.App.appearance("Appearance"),
                Section.App.fiat("Fiat currency", AppSettings.selectedFiatCode),
                Section.App.experimental("Experimental 🧪")
            ]),
            (section: .general, items: [
                Section.General.terms("Terms of use"),
                Section.General.privacyPolicy("Privacy policy"),
                Section.General.licenses("Licenses"),
                Section.General.getInTouch("Get in touch"),
                Section.General.rateTheApp("Rate the app"),
                Section.General.appVersion("App version", "\(app.marketingVersion) (\(app.buildVersion))"),
            ]),
            (section: .advanced, items: [Section.Advanced.advanced("Advanced")])
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
                             .selectedFiatCurrencyChanged,
                             .updatedExperemental] {
            notificationCenter.addObserver(
                self,
                selector: #selector(reload),
                name: notification,
                object: nil)
        }
    }

    private func showOwnerKeys() {
        let vc = OwnerKeysListViewController()
        show(vc, sender: self)
    }

    private func openPasscode() {
        let vc = PasscodeSettingsViewController()
        show(vc, sender: self)
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
        case Section.App.ownerKeys(let name, let count):
            return tableView.basicCell(name: name, detail: count, indexPath: indexPath)

        case Section.App.passcode(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.App.appearance(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.App.fiat(let name, let value):
            return tableView.basicCell(name: name, detail: value, indexPath: indexPath)

        case Section.App.experimental(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.terms(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.privacyPolicy(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.licenses(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.getInTouch(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.rateTheApp(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.General.appVersion(let name, let version):
            return tableView.infoCell(name: name, info: version, indexPath: indexPath)

        case Section.Advanced.advanced(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        default:
            return UITableViewCell()
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.App.ownerKeys:
            showOwnerKeys()

        case Section.App.passcode:
            openPasscode()

        case Section.App.appearance:
            let appearanceViewController = ChangeDisplayModeTableViewController()
            show(appearanceViewController, sender: self)

        case Section.App.fiat:
            let selectFiatViewController = SelectFiatViewController()
            show(selectFiatViewController, sender: self)

        case Section.App.experimental:
            let experimentalViewController = ExperimentalViewController()
            show(experimentalViewController, sender: self)

        case Section.General.terms:
            openInSafari(legal.termsURL)

        case Section.General.privacyPolicy:
            openInSafari(legal.privacyURL)

        case Section.General.licenses:
            openInSafari(legal.licensesURL)

        case Section.General.getInTouch:
            let getInTouchVC = GetInTouchView()
            let hostingController = UIHostingController(rootView: getInTouchVC)
            show(hostingController, sender: self)

        case Section.General.rateTheApp:
            let url = App.configuration.contact.appStoreReviewURL
            UIApplication.shared.open(url, options: [:], completionHandler: nil)

        case Section.Advanced.advanced:
            let advancedVC = AdvancedAppSettings()
            let hostingController = UIHostingController(rootView: advancedVC)
            show(hostingController, sender: self)

        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.General.appVersion:
            return InfoCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        switch section {
        case .general, .advanced:
            return sectionHeaderHeight
        default:
            return 0
        }
    }
}
