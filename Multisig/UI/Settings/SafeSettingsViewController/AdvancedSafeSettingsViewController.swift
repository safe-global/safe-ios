//
//  AdvancedSafeSettingsViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version

fileprivate protocol SectionItem {}

class AdvancedSafeSettingsViewController: UITableViewController {    
    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var safe: Safe!
    private var sections = [SectionItems]()

    enum Section {
        case fallbackHandler(String)
        case guardInfo(String)
        case nonce(String)
        case modules(String)

        enum FallbackHandler: SectionItem {
            case fallbackHandler(AddressInfo?)
            case fallbackHandlerHelpLink
        }

        enum GuardInfo: SectionItem {
            case guardInfo(AddressInfo?)
            case guardInfoHelpLink
        }

        enum Nonce: SectionItem {
            case nonce(String)
        }

        enum Module: SectionItem {
            case module(AddressInfo)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            safe = try Safe.getSelected()!
            buildSections()
        } catch {
            fatalError()
        }

        navigationItem.title = "Advanced"
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(HelpLinkTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.backgroundColor = .backgroundSecondary
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsSafeAdvanced)
    }

    private func buildSections() {
        sections = []

        sections.append(
            (section: .fallbackHandler("FALLBACK HANDLER"),
             items: [Section.FallbackHandler.fallbackHandler(safe.fallbackHandlerInfo),
                     Section.FallbackHandler.fallbackHandlerHelpLink])
        )

        if let contractVersion = safe.contractVersion,
           let version = Version(contractVersion),
           version >= Version(1, 3, 0) {
            sections.append(
                (section: .guardInfo("GUARD"),
                 items: [Section.GuardInfo.guardInfo(safe.guardInfo),
                         Section.GuardInfo.guardInfoHelpLink])
            )
        }

        sections.append(
            (section: .nonce("NONCE"),
             items: [Section.Nonce.nonce(safe.nonce?.description ?? "0")])
        )

        if let modules = safe.modulesInfo, !modules.isEmpty {
            sections.append((section: .modules("ADDRESSES OF ENABLED MODULES"),
                 items: modules.map { Section.Module.module($0) }))
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

        case Section.FallbackHandler.fallbackHandler(let info):
            if let info = info {
                let (name, _) = NamingPolicy.name(for: info.address,
                                                            info: info,
                                                            chainId: safe.chain!.id!)
                return addressDetailsCell(address: info.address,
                                          title: name,
                                          imageUri: info.logoUri,
                                          indexPath: indexPath,
                                          browseURL: safe.chain!.browserURL(address: info.address.checksummed),
                                          prefix: safe.chain!.shortName)
            } else {
                return tableView.basicCell(
                    name: "Not set", indexPath: indexPath, disclosureImage: nil, canSelect: false)
            }

        case Section.FallbackHandler.fallbackHandlerHelpLink:
            return helpLinkCell(text: "What is a fallback handler and how does it relate to the Safe Account",
                                url: App.configuration.help.fallbackHandlerURL,
                                indexPath: indexPath)

        case Section.GuardInfo.guardInfo(let info):
            if let info = info {
                let (name, _) = NamingPolicy.name(for: info.address,
                                                            info: info,
                                                            chainId: safe.chain!.id!)
                return addressDetailsCell(address: info.address,
                                          title: name,
                                          imageUri: info.logoUri,
                                          indexPath: indexPath,
                                          browseURL: safe.chain!.browserURL(address: info.address.checksummed),
                                          prefix: safe.chain!.shortName)
            } else {
                return tableView.basicCell(
                    name: "Not set", indexPath: indexPath, disclosureImage: nil, canSelect: false)
            }

        case Section.GuardInfo.guardInfoHelpLink:
            return helpLinkCell(text: "What is a guard and how that is used",
                                url: App.configuration.help.guardURL,
                                indexPath: indexPath)

        case Section.Nonce.nonce(let nonce):
            return tableView.basicCell(name: nonce,
                                       indexPath: indexPath,
                                       disclosureImage: nil,
                                       canSelect: false)

        case Section.Module.module(let info):
            let (name, _) = NamingPolicy.name(for: info.address,
                                                        info: info,
                                                        chainId: safe.chain!.id!)
            return addressDetailsCell(address: info.address,
                                      title: name,
                                      imageUri: info.logoUri,
                                      indexPath: indexPath,
                                      browseURL: safe.chain!.browserURL(address: info.address.checksummed),
                                      prefix: safe.chain!.shortName)

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
        case Section.guardInfo(let name):
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.FallbackHandler.fallbackHandler(let info):
            if info == nil {
                return BasicCell.rowHeight
            }
        case Section.GuardInfo.guardInfo(let info):
            if info == nil {
                return BasicCell.rowHeight
            }
        case Section.Nonce.nonce:
            return BasicCell.rowHeight
        default:
            break
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        BasicCell.rowHeight
    }

    private func addressDetailsCell(address: Address,
                                    title: String?,
                                    imageUri: URL?,
                                    indexPath: IndexPath,
                                    browseURL: URL?,
                                    prefix: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: title, imageUri: imageUri, browseURL: browseURL, prefix: prefix)
        return cell
    }

    private func helpLinkCell(text: String, url: URL, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(HelpLinkTableViewCell.self, for: indexPath)
        cell.descriptionLabel.hyperLinkLabel(linkText: text)
        cell.url = url
        return cell
    }
}
