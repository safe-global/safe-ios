//
//  SafeSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

fileprivate protocol SectionItem {}

class SafeSettingsViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService
    let tableBackgroundColor: UIColor = .backgroundPrimary
    let advancedSectionHeaderHeight: CGFloat = 28

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var currentDataTask: URLSessionTask?
    private var sections = [SectionItems]()
    private var safe: Safe?
    private var ensLoader: ENSNameLoader?

    private var changeConfirmationsFlow: ChangeConfirmationsFlow!

    enum Section {
        case name(String)
        case requiredConfirmations(String)
        case ownerAddresses(String)
        case safeVersion(String)
        case ensName(String)
        case advanced

        enum Name: SectionItem {
            case name(String)
        }

        enum RequiredConfirmations: SectionItem {
            case confirmations(String)
        }

        enum OwnerAddresses: SectionItem {
            case ownerInfo(AddressInfo)
        }

        enum ContractVersion: SectionItem {
            case versionInfo(AddressInfo, ImplementationVersionState, String)
        }

        enum EnsName: SectionItem {
            case ensName
        }

        enum Advanced: SectionItem {
            case advanced(String)
            case removeSafe
        }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = tableBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(ContractVersionStatusCell.self)
        tableView.registerCell(LoadingValueCell.self)
        tableView.registerCell(RemoveCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .selectedSafeUpdated,
                             .addressbookChanged,
                             .chainSettingsChanged] {
            notificationCenter.addObserver(
                self,
                selector: #selector(update),
                name: notification,
                object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsSafe)
    }

    @objc func update() {
        do {
            // it may happen that data is deleted, so we should just finish gracefully.
            guard let selectedSafe = try Safe.getSelected() else {
                return
            }
            safe = selectedSafe
            updateSections()
        } catch {
            onError(GSError.error(description: "Failed to load safe settings", error: error))
        }
        tableView.reloadData()
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            guard let selectedSafe = try Safe.getSelected() else {
                return
            }
            safe = selectedSafe
            currentDataTask = clientGatewayService.asyncSafeInfo(safeAddress: selectedSafe.addressValue,
                                                                 chainId: selectedSafe.chain!.id!) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        self.onError(GSError.error(description: "Failed to load safe settings", error: error))
                    }
                case .success(let safeInfo):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        if let safe = self.safe {
                            safe.update(from: safeInfo)
                            self.updateSections()
                            self.ensLoader = ENSNameLoader(safe: safe, delegate: self)
                        }
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load safe settings", error: error))
        }
    }

    private func updateSections() {
        sections = []

        guard let safe = safe else { return }

        sections += [
            (section: .name("Safe Name"), items: [Section.Name.name(safe.name ?? "Safe \(safe.addressValue.ellipsized())")]),

            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(safe.threshold!) out of \(safe.ownersInfo!.count)")]),

            (section: .ownerAddresses("Owner addresses"),
             items: safe.ownersInfo!.map { Section.OwnerAddresses.ownerInfo($0) }),

            (section: .safeVersion("Safe version"),
             items: [Section.ContractVersion.versionInfo(safe.implementationInfo!, safe.implementationVersionState!, safe.version!)]),

            (section: .ensName("ENS name"), items: [Section.EnsName.ensName]),

            (section: .advanced, items: [
                Section.Advanced.advanced("Advanced"),
                Section.Advanced.removeSafe])
        ]
    }

    // MARK: - Table view data source

    // validate index path to prevent crashes due to racing when using async network calls
    func isValid(path indexPath: IndexPath) -> Bool {
        indexPath.section < sections.count && indexPath.row < sections[indexPath.section].items.count
    }

    // validate sections path to prevent crashes due to racing when using async network calls
    func isValid(section: Int) -> Bool {
        section < sections.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isValid(section: section) else { return 0 }
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isValid(path: indexPath), let safe = safe else {
            return UITableViewCell()
        }
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.RequiredConfirmations.confirmations(let name):
            return tableView.basicCell(name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        case Section.OwnerAddresses.ownerInfo(let info):
            let keyInfo = try? KeyInfo.keys(addresses: [info.address]).first
            let (name, _) = NamingPolicy.name(for: info.address,
                                                        info: info,
                                                        chainId: safe.chain!.id!)

            return addressDetailsCell(address: info.address,
                                      name: name,
                                      indexPath: indexPath,
                                      badgeName: keyInfo?.keyType.imageName,
                                      browseURL: safe.chain!.browserURL(address: info.address.checksummed),
                                      prefix: safe.chain!.shortName)

        case Section.ContractVersion.versionInfo(let info, let status, let version):
            return safeVersionCell(info: info,
                                   status: status,
                                   version: version,
                                   indexPath: indexPath,
                                   prefix: safe.chain!.shortName)

        case Section.EnsName.ensName:
            if ensLoader == nil || ensLoader!.isLoading {
                return loadingCell(name: nil, indexPath: indexPath)
            } else {
                return loadingCell(name: safe.ensName ?? "Reverse record not set", indexPath: indexPath)
            }

        case Section.Advanced.advanced(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.Advanced.removeSafe:
            return tableView.removeCell(indexPath: indexPath, title: "Remove Safe") { [weak self] in
                guard let `self` = self else { return }
                let alertController = UIAlertController(
                    title: nil,
                    message: "Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost.",
                    preferredStyle: .actionSheet)

                if let popoverPresentationController = alertController.popoverPresentationController {
                    popoverPresentationController.sourceView = tableView
                    popoverPresentationController.sourceRect = tableView.rectForRow(at: indexPath)
                }

                let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
                    if let safe = self.safe {
                        Safe.remove(safe: safe)
                    }
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(remove)
                alertController.addAction(cancel)
                self.present(alertController, animated: true)
            }
        default:
            return UITableViewCell()
        }
    }

    private func addressDetailsCell(address: Address,
                                    name: String?,
                                    indexPath: IndexPath,
                                    badgeName: String? = nil,
                                    browseURL: URL? = nil,
                                    prefix: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: name, badgeName: badgeName, browseURL: browseURL, prefix: prefix)
        return cell
    }

    private func safeVersionCell(info: AddressInfo,
                                 status: ImplementationVersionState,
                                 version: String,
                                 indexPath: IndexPath,
                                 prefix: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(ContractVersionStatusCell.self, for: indexPath)
        cell.setAddress(info, status: status, version: version, prefix: prefix)
        cell.selectionStyle = .none
        cell.onViewDetails = { [weak self] in
            guard let `self` = self, let safe = self.safe else { return }
            self.openInSafari(safe.chain!.browserURL(address: info.address.checksummed))
        }
        return cell
    }

    private func loadingCell(name: String?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(LoadingValueCell.self, for: indexPath)
        if let name = name {
            cell.setTitle(name)
        } else {
            cell.displayLoading()
        }
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isValid(path: indexPath) else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(_):
            guard let safe = safe else { return }
            let editSafeNameViewController = EditSafeNameViewController()
            editSafeNameViewController.name = safe.name
            editSafeNameViewController.completion = { name in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.safe?.update(name: name)
                    self.navigationController?.popViewController(animated: true)
                }
            }
            show(editSafeNameViewController, sender: self)

        case Section.RequiredConfirmations.confirmations(_):
            changeConfirmationsFlow = ChangeConfirmationsFlow(safe: safe!, navigationController: navigationController!, completion: { [unowned self] _ in
                changeConfirmationsFlow = nil //WHY?
                // completion() // TODO implement
            })
            changeConfirmationsFlow.start()
            break
        case Section.Advanced.advanced(_):
            let advancedSafeSettingsViewController = AdvancedSafeSettingsViewController()
            let ribbon = RibbonViewController(rootViewController: advancedSafeSettingsViewController)
            show(ribbon, sender: self)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard isValid(path: indexPath) else {
            return 0
        }
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.OwnerAddresses.ownerInfo:
            return UITableView.automaticDimension

        case Section.ContractVersion.versionInfo:
            return UITableView.automaticDimension

        case Section.EnsName.ensName:
            return LoadingValueCell.rowHeight

        case Section.Advanced.removeSafe:
            return RemoveCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        guard isValid(section: _section) else {
            return nil
        }
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.name(let name):
            view.setName(name)

        case Section.requiredConfirmations(let name):
            view.setName(name)

        case Section.ownerAddresses(let name):
            view.setName(name)

        case Section.safeVersion(let name):
            view.setName(name)

        case Section.ensName(let name):
            view.setName(name)

        case Section.advanced:
            break
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        guard isValid(section: _section) else {
            return 0
        }
        let section = sections[_section].section
        switch section {
        case Section.name:
            return 0
        case Section.advanced:
            return advancedSectionHeaderHeight
        default:
            return BasicHeaderView.headerHeight
        }
    }
}

extension SafeSettingsViewController: ENSNameLoaderDelegate {
    func ensNameLoaderDidLoadName(_ loader: ENSNameLoader) {
        tableView.reloadData()
    }
}
