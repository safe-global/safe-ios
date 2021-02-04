//
//  AdvancedSafeSettingsViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}
class AdvancedSafeSettingsViewController: UITableViewController {    
    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var safe: Safe!
    private var currentDataTask: URLSessionTask?
    private var sections = [SectionItems]()
    enum Section {
        case fallbackHandler(String)
        case nonce(String)
        case modules(String)

        enum FallbackHandler: SectionItem {
            case fallbackHandler(String?, String?)
            case fallbackHandlerHelpLink
        }

        enum Nonce: SectionItem {
            case nonce(String)
        }

        enum Module: SectionItem {
            case module(String, String)
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            safe = try Safe.getSelected()!
            buildSections()
        } catch {
            //onError(GSError.error(description: "Failed to load safe settings", error: error))
        }

        navigationItem.title = "Advanced"
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(HelpLinkTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsSafeAdvanced)
    }

    private func buildSections() {
        let fallbackHandler = App.shared.gnosisSafe.hasFallbackHandler(safe: safe) ? safe.fallbackHandler?.checksummed : nil
        let fallbackHanderTitle = App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: safe.fallbackHandler)
        sections = [
            (section: .fallbackHandler("FALLBACK HANDLER"), items: [Section.FallbackHandler.fallbackHandler(fallbackHanderTitle, fallbackHandler), Section.FallbackHandler.fallbackHandlerHelpLink]),

            (section: .nonce("NONCE"),
             items: [Section.Nonce.nonce(safe.nonce?.description ?? "0")]),
        ]

        if let modules = safe.modules, !modules.isEmpty {
            sections.append((section: .modules("ADDRESSES OF ENABLED MODULES"),
                             items: modules.map { Section.Module.module("Unknown", $0.checksummed) }))
        }
    }
}

extension AdvancedSafeSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.FallbackHandler.fallbackHandler(let title, let address):
            if let address = address {
                return addressDetailsCell(address: address, title: title, indexPath: indexPath)
            } else {
                return basicCell(name: "Not set", indexPath: indexPath)
            }
        case Section.FallbackHandler.fallbackHandlerHelpLink:
            return fallbackHandlerHelpLinkCell(indexPath: indexPath)
        case Section.Nonce.nonce(let nonce):
            return basicCell(name: nonce, indexPath: indexPath)
        case Section.Module.module(let name, let address):
            return addressDetailsCell(address: address, title: name, indexPath: indexPath)
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.fallbackHandler(let name):
            view.setName(name)

        case Section.nonce(let name):
            view.setName(name)

        case Section.modules(let name):
            view.setName(name)
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    private func basicCell(name: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setDisclosureImage(nil)
            cell.selectionStyle = .none
        return cell
    }

    private func addressDetailsCell(address: String, title: String?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address,label: title)
        return cell
    }

    private func fallbackHandlerHelpLinkCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(HelpLinkTableViewCell.self, for: indexPath)
        return cell
    }
}
