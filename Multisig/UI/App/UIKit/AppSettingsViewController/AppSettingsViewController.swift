//
//  AppSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 10.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class AppSettingsViewController: UITableViewController {
    let app = App.configuration.app
    let tableBackgroundColor: UIColor = .gnoWhite
    let advancedSectionHeaderHeight: CGFloat = 28

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    enum Section {
        case general
        case advanced

        enum General: SectionItem {
            case importKey(String)
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
        tableView.registerCell(InfoCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        buildSections()
    }

    private func buildSections() {
        sections = [
            (section: .general, items: [
                Section.General.importKey("Import owner key"),
                Section.General.appVersion("App version", app.marketingVersion),
                Section.General.network("Network", app.network.rawValue),
            ]),
            (section: .advanced, items: [Section.Advanced.advanced("Advanced")])
        ]
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

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.General.importKey(_):
            break
        case Section.Advanced.advanced(_):
            break
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
