//
//  KeySecurityOverviewViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/8/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class KeySecurityOverviewViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private var infoButton: UIBarButtonItem!

    private var createPasswordFlow: SetupRecoveryKitFlow!

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()

    enum Section {
        case enabledFactors(String)
        case otherFactors(String)
        case info

        enum Factor: SectionItem {
            case factor(String, String?, String, Bool, Bool)
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
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        title = "Recovery Kit"

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        infoButton = UIBarButtonItem(image: UIImage(named: "ico-info-24"),
                style: UIBarButtonItem.Style.plain,
                target: self,
                action: #selector(showHelpScreen))
        navigationItem.rightBarButtonItem = infoButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenSecurityOverview)
    }

    @objc func showHelpScreen() { 

    }

    override func reloadData() {
        buildSections()
        tableView.reloadData()
    }

    private func buildSections() {
        sections = []

        // TODO: Build sections properly
        sections.append(SectionItems(section: .enabledFactors("YOUR SECURITY FACTORS"), items: [
            Section.Factor.factor("Email address", "ann.fischer@gmail", "ico-eMail", true, true),
            Section.Factor.factor("Trusted device", nil, "ico-mobile", false, false),
            Section.Factor.factor("Security password", nil, "ico-password", false, false)]))

        sections.append(SectionItems(section: .info,
                                     items: [Section.Info.info("More factors are coming soon!", "ico-clock")]))

        let header = TableHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 120))
        header.set("Protect your owner from unauthorised access and ensure easy recovery. We recommend to enable at least 2 recovery factors.", centered: true, linesCount: 3, backgroundColor: .backgroundPrimary)
        
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
        case .enabledFactors(_), .otherFactors(_):
            if case let Section.Factor.factor(name, value, image, isDefault, selected) = factor {
                let cell = tableView.dequeueCell(SecurityFactorTableViewCell.self, for: indexPath)
                cell.set(name: name,
                         icon: UIImage(named: image)!,
                         value: value,
                         tag: isDefault ? "(Default)" : nil,
                         selected: selected)

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            show(TrustedEmailViewController(), sender: self)
        } else if indexPath.row == 1 {
            show(TrustedDeviceViewController(), sender: self)
        } else {
            let factor = sections[indexPath.section].items[indexPath.row]

            if case let Section.Factor.factor(name, value, image, isDefault, selected) = factor {
                createPasswordFlow = SetupRecoveryKitFlow(completion: { [weak self] _ in
                    self?.createPasswordFlow = nil
                    self?.buildSections()
                })
                present(flow: createPasswordFlow)
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view: UIView?

        var title: String
        switch sections[section].section {
        case .enabledFactors(let name):
            title = name
        case .otherFactors(let name):
            title = name
        case .info:
            title = ""
        }

        view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        (view as! BasicHeaderView).setName(title, backgroundColor: .clear, style: .caption2Secondary)

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section].section {
        case .info:
            return 0
        default:
            return BasicHeaderView.headerHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].section {
        case .info:
            return UITableView.automaticDimension
        default:
            return SecurityFactorTableViewCell.rowHeight
        }
    }
}
