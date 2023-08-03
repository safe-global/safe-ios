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

    // We need this to get the correct order of owners, this is needed for replace&remove owner
    //and not guaranteed by SafeInfo endpoint
    private var safeOwners: [AddressInfo] = []
    private var socialOwnerOnly = false

    private var ensLoader: ENSNameLoader?

    private var changeConfirmationsFlow: ChangeConfirmationsFlow!
    private var removeOwnerFlow: RemoveOwnerFlow!
    private var replaceOwnerFlow: ReplaceOwnerFromSettingsFlow!
    private var addOwnerFlow: AddOwnerFlowFromSettings!
    
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
            case socialLoginInfoBox
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
        tableView.registerCell(SocialLoginInfoTableViewCell.self)
        tableView.registerCell(ContractVersionStatusCell.self)
        tableView.registerCell(LoadingValueCell.self)
        tableView.registerCell(RemoveCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerHeaderFooterView(OwnerHeaderView.self)

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .selectedSafeUpdated,
                             .selectedSafeChanged,
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
            onError(GSError.error(description: "Failed to load Safe Account settings", error: error))
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
                        self.onError(GSError.error(description: "Failed to load Safe Account settings", error: GSError.detailedError(from: error)))
                    }
                case .success(let safeInfo):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        if let safe = self.safe {
                            safe.update(from: safeInfo)
                            self.reloadSafeOwners()
                            self.ensLoader = ENSNameLoader(safe: safe, delegate: self)
                        }
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load Safe Account settings", error: GSError.detailedError(from: error)))
        }
    }

    func reloadSafeOwners() {
        currentDataTask?.cancel()
        guard let safe = safe else {
            updateSections()
            return
        }

        currentDataTask = SafeTransactionController.shared.getOwners(safe: safe.addressValue, chain: safe.chain!) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                self.onError(GSError.error(description: "Failed to load Safe Account owners", error: GSError.detailedError(from: error)))
            case .success(let owners):
                self.safeOwners = owners.compactMap { owner in
                    AddressInfo.init(address: owner)
                }

                self.updateSections()
                self.onSuccess()
            }
        }
    }

    private func updateSections() {
        sections = []

        guard
            let safe = safe,
            let threshold = safe.threshold,
            let ownersInfo = safe.ownersInfo,
            let implementationInfo = safe.implementationInfo,
            let implementationVersionState = safe.implementationVersionState,
            let version = safe.version
        else { return }

        var ownersInfoItems: [Section.OwnerAddresses] = []
        // Add social login info box only if there is only one owner and it is social login
        if ownersInfo.count == 1 {
            let owner = ownersInfo.first!
            ownersInfoItems.append(Section.OwnerAddresses.ownerInfo(owner))
            let keyInfo = try? KeyInfo.keys(addresses: [owner.address]).first
            if keyInfo?.keyType == .web3AuthApple || keyInfo?.keyType == .web3AuthGoogle {
                ownersInfoItems.append(Section.OwnerAddresses.socialLoginInfoBox)
                socialOwnerOnly = true
            }
        } else {
            ownersInfoItems = ownersInfo.map { Section.OwnerAddresses.ownerInfo($0) }
            socialOwnerOnly = false
        }

        sections += [
            (section: .name("Safe Account Name"), items: [Section.Name.name(safe.name ?? "Safe \(safe.addressValue.ellipsized())")]),

            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(threshold) out of \(ownersInfo.count)")]),

            (section: .ownerAddresses("Owners"),
             items: ownersInfoItems),

            (section: .safeVersion("Safe Account base contract version"),
             items: [Section.ContractVersion.versionInfo(implementationInfo, implementationVersionState, version)]),

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
            let canChangeConfirmations = ChangeConfirmationsFlow.canChangeConfirmations(safe: safe)
            return tableView.basicCell(name: name,
                                       indexPath: indexPath,
                                       disclosureImage: canChangeConfirmations ? UIImage(named: "arrow") : nil,
                                       canSelect: canChangeConfirmations)

        case Section.OwnerAddresses.ownerInfo(let info):
            let keyInfo = try? KeyInfo.keys(addresses: [info.address]).first
            let (name, _) = NamingPolicy.name(for: info.address,
                                                        info: info,
                                                        chainId: safe.chain!.id!)
            var browseUrl: URL? = nil
            if keyInfo == nil {
                 browseUrl = safe.chain!.browserURL(address: info.address.checksummed)
            }
            let cell = addressDetailsCell(address: info.address,
                                      name: keyInfo?.displayName,
                                      indexPath: indexPath,
                                      badgeName: keyInfo?.keyType.badgeName,
                                      browseURL: browseUrl,
                                      prefix: safe.chain!.shortName)
            cell.selectionStyle = .default
            if keyInfo == nil {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
            }

            return cell

        case Section.OwnerAddresses.socialLoginInfoBox:
            let infoBoxCell = tableView.dequeueCell(SocialLoginInfoTableViewCell.self, for: indexPath)
            infoBoxCell.setup(
                onAddOwner: { [unowned self] in
                    Tracker.trackEvent(.userAddOwner)
                    addOwner()
                },
                onLearnMore: { [unowned self] in
                    Tracker.trackEvent(.userLearnMore)
                    openInSafari(App.configuration.help.addOwnersURL)
                }
            )
            infoBoxCell.selectionStyle = .none
            return infoBoxCell

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

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isValid(path: indexPath), let safe = safe, !safe.isReadOnly, !safeOwners.isEmpty else { return nil }

        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.OwnerAddresses.ownerInfo(let info):
            guard let ownerIndex = (safeOwners.firstIndex { $0.address == info.address }) else { return nil }

            var actions: [UIContextualAction] = []

            let prevOwner = safeOwners.before(ownerIndex)

            if safeOwners.count > 1 {
                let removeOwnerAction = UIContextualAction(style: .destructive, title: "Remove") {
                    [unowned self] _, _, completion in
                    self.remove(owner: info.address, prevOwner: prevOwner?.address)
                    completion(true)
                }
                removeOwnerAction.backgroundColor = .error

                actions.append(removeOwnerAction)
            }

            let replaceAction = UIContextualAction(style: .normal, title: "Replace") {
                [unowned self] _, _, completion in
                self.replace(owner: info.address, prevOwner: prevOwner?.address)
                completion(true)
            }
            replaceAction.backgroundColor = .labelTertiary

            actions.append(replaceAction)
            return UISwipeActionsConfiguration(actions: actions)
        default:
            return nil
        }
    }

    func addOwner() {
        addOwnerFlow = AddOwnerFlowFromSettings(safe: safe!) { [unowned self] _ in
            addOwnerFlow = nil
        }
        present(flow: addOwnerFlow)
        Tracker.trackEvent(.addOwnerFromSettings)
    }

    func replace(owner: Address, prevOwner: Address?) {
        replaceOwnerFlow = ReplaceOwnerFromSettingsFlow(
            ownerToReplace: owner,
            prevOwner: prevOwner,
            safe: safe!
        ) { [unowned self] _ in
            replaceOwnerFlow = nil
        }
        present(flow: replaceOwnerFlow)
        Tracker.trackEvent(.replaceOwnerFromSettings)
    }

    func remove(owner: Address, prevOwner: Address?) {
        removeOwnerFlow = RemoveOwnerFlow(owner: owner, prevOwner: prevOwner, safe: safe!) { [unowned self] _ in
            removeOwnerFlow = nil
        }
        present(flow: removeOwnerFlow)
        Tracker.trackEvent(.userRemoveOwnerFromSettings)
    }

    private func addressDetailsCell(address: Address,
                                    name: String?,
                                    indexPath: IndexPath,
                                    badgeName: String? = nil,
                                    browseURL: URL? = nil,
                                    prefix: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        let keyInfo = try? KeyInfo.keys(addresses: [address]).first
        let copyEnabled = keyInfo == nil
        cell.setAccount(address: address, label: name, badgeName: badgeName, copyEnabled: copyEnabled,  browseURL: browseURL, prefix: prefix)
        // Remove separator line between address item and social login info box
        if socialOwnerOnly {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width, bottom: 0, right: 0)
        }
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
            changeConfirmationsFlow = ChangeConfirmationsFlow(safe: safe) { [unowned self] _ in
                changeConfirmationsFlow = nil
            }

            guard changeConfirmationsFlow != nil else {
                return
            }

            present(flow: changeConfirmationsFlow)
        case Section.Advanced.advanced(_):
            let advancedSafeSettingsViewController = AdvancedSafeSettingsViewController()
            let ribbon = RibbonViewController(rootViewController: advancedSafeSettingsViewController)
            show(ribbon, sender: self)
        case Section.OwnerAddresses.ownerInfo(let addressInfo):
            let keyInfo = try? KeyInfo.keys(addresses: [addressInfo.address]).first
            if let keyInfo = keyInfo {
                let vc = OwnerKeyDetailsViewController(keyInfo: keyInfo)
                show(vc, sender: self)
            }
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

        case Section.OwnerAddresses.socialLoginInfoBox:
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
        guard isValid(section: _section), let safe = safe else {
            return nil
        }
        let section = sections[_section].section
        var view: UIView?
        switch section {
        case Section.name(let name):
            view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            (view as! BasicHeaderView).setName(name)

        case Section.requiredConfirmations(let name):
            view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            (view as! BasicHeaderView).setName(name)

        case Section.ownerAddresses(let name):
            view = tableView.dequeueHeaderFooterView(OwnerHeaderView.self)
            let ownerHeaderView = view as! OwnerHeaderView
            ownerHeaderView.setName(name)
            ownerHeaderView.setNumber(safe.ownersInfo?.count)
            ownerHeaderView.addButton.isHidden = safe.isReadOnly

            ownerHeaderView.onAdd = { [unowned self] in
                Tracker.trackEvent(.addOwnerFromSettings)
                addOwner()
            }

        case Section.safeVersion(let name):
            view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            (view as! BasicHeaderView).setName(name)

        case Section.ensName(let name):
            view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            (view as! BasicHeaderView).setName(name)

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


extension BidirectionalCollection {
    typealias Element = Self.Iterator.Element

    func before(_ itemIndex: Self.Index?) -> Element? {
        if let itemIndex = itemIndex {
            let firstItem: Bool = (itemIndex == startIndex)
            if firstItem {
                return nil
            } else {
                return self[index(before: itemIndex)]
            }
        }
        return nil
    }
}
