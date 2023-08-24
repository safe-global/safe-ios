//
//  TrustedEmailViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/21/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class TrustedEmailViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()

    enum Section {
        case factor
        case info

        enum Factor: SectionItem {
            case factor(String, String, String)
        }

        enum Info: SectionItem {
            case info(String, String)
        }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(SecurityFactorTableViewCell.self)
        tableView.registerCell(WarningTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none

        title = "Email address"

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    override func reloadData() {
        buildSections()
        tableView.reloadData()
    }

    private func buildSections() {
        sections = []

        // TODO: Build sections properly
        sections.append(SectionItems(section: .factor,
                                     items: [Section.Factor.factor("ann.fischer@gmail.com",
                                                                   "Primary recovery factor",
                                                                   "ico-mobile")]))
        sections.append(SectionItems(section: .info,
                                     items: [Section.Info.info("This is your default recovery method. You cannot remove or change it.", "ico-info-24")]))

        let header = TableHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 120))
        header.set("Your email address is used to login and to store the key share of your owner. You can use this email to confirm it’s you during recovery.", centered: true, linesCount: 3, backgroundColor: .backgroundPrimary)

        tableView.tableHeaderView = header
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let factor = sections[indexPath.section].items[indexPath.row]
        switch sections[indexPath.section].section {
        case .factor:
            if case let Section.Factor.factor(name, value, image) = factor {
                let cell = tableView.dequeueCell(SecurityFactorTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                cell.set(name: name,
                         icon: UIImage(named: image)!,
                         value: value,
                         showDisclosure: false)

                return cell
            }
        case .info:
            if case let Section.Info.info(text, image) = factor {
                let cell = tableView.dequeueCell(WarningTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                cell.set(image: UIImage(named: image)?.withTintColor(.info, renderingMode: .alwaysOriginal),
                         description: text,
                         backgroundColor: .infoBackground)
                cell.backgroundColor = .clear

                return cell
            }
        }

        return UITableViewCell()
    }

}
