//
//  DappsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class DappsViewController: UITableViewController {
    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    enum Section {
        case walletConnect(String)
        case dapp(String)

        enum WalletConnect: SectionItem {
            case activeSession(String)
            case noSessions(String)
        }

        enum Dapp: SectionItem {
            case name(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .gnoWhite
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerCell(BasicCell.self)

        updateSections()
    }

    private func updateSections() {
        sections = [
            (section: .walletConnect("WalletConnect"), items: [Section.WalletConnect.noSessions("No active sessions")])
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
        case Section.WalletConnect.noSessions(let name):
            return basicCell(name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        default:
            return UITableViewCell()
        }
    }

    #warning("Move to extension")
    private func basicCell(name: String,
                           indexPath: IndexPath,
                           withDisclosure: Bool = true,
                           canSelect: Bool = true) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        if !withDisclosure {
            cell.setDisclosureImage(nil)
        }
        if !canSelect {
            cell.selectionStyle = .none
        }
        return cell
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}
