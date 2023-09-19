//
//  SecurityKitViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/16/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class SafeSecurityViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

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

    private var changeConfirmationsFlow: ChangeConfirmationsFlow!
    private var removeOwnerFlow: RemoveOwnerFlow!
    private var replaceOwnerFlow: ReplaceOwnerFromSettingsFlow!
    private var addOwnerFlow: AddOwnerFlowFromSettings!
    private var setupRecoveryKitFlow: SetupRecoveryKitFlow!

    enum Section {
        case status
        case requiredConfirmations(String)
        case ownerAddresses(String)

        enum Status: SectionItem {
            case status(SafeSecurityStatus, [(Bool, String)])
        }

        enum RequiredConfirmations: SectionItem {
            case confirmations(String)
        }

        enum OwnerAddresses: SectionItem {
            case ownerInfo(AddressInfo)
        }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account security"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = tableBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = InfoTableFooterView.estimatedHeight
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(SecurityStatusTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerHeaderFooterView(OwnerHeaderView.self)
        tableView.registerHeaderFooterView(InfoTableFooterView.self)

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

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
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
            let ownersInfo = safe.ownersInfo
        else { return }

        var ownersInfoItems: [Section.OwnerAddresses] = []
        // Add social login info box only if there is only one owner and it is social login
        if ownersInfo.count == 1 {
            let owner = ownersInfo.first!
            ownersInfoItems.append(Section.OwnerAddresses.ownerInfo(owner))
            let keyInfo = try? KeyInfo.keys(addresses: [owner.address]).first
            if keyInfo?.keyType == .web3AuthApple || keyInfo?.keyType == .web3AuthGoogle {
                socialOwnerOnly = true
            }
        } else {
            ownersInfoItems = ownersInfo.map { Section.OwnerAddresses.ownerInfo($0) }
            socialOwnerOnly = false
        }
        
        sections = [(section: .status, items: [Section.Status.status(safe.security, [
            (safe.securityHasBackup, "Back up your owners"),
            (safe.securityHasEnoughOwners, "Add more owners"),
            (safe.securityHasRecommendedThreshold , "Increase confirmation threshold")
        ])])]
        
        sections += [
            (section: .ownerAddresses("Owners"),
             items: ownersInfoItems),
            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(threshold) out of \(ownersInfo.count)")])
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
        case Section.Status.status(let state, let actions):
            let cell = tableView.dequeueCell(SecurityStatusTableViewCell.self)
            cell.set(title: "Your account security",
                     subTitle: "Increase the security by following our recommendations",
                     imageName: state == .high ? "ico-account-secure" : "ico-account-insecure", actions: actions)
            return cell
        case Section.RequiredConfirmations.confirmations(let name):
            let canChangeConfirmations = ChangeConfirmationsFlow.canChangeConfirmations(safe: safe)
            return tableView.basicCell(name: name,
                                       indexPath: indexPath,
                                       disclosureImage: canChangeConfirmations ? UIImage(named: "arrow") : nil,
                                       canSelect: canChangeConfirmations)

        case Section.OwnerAddresses.ownerInfo(let info):
            return ownerInfoCell(info, safe, indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    fileprivate func ownerInfoCell(_ info: (AddressInfo), _ safe: Safe, _ indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = try? KeyInfo.keys(addresses: [info.address]).first
        let (name, _) = NamingPolicy.name(for: info.address,
                                          info: info,
                                          chainId: safe.chain!.id!)
        var browseUrl: URL? = nil
        if keyInfo == nil {
            browseUrl = safe.chain!.browserURL(address: info.address.checksummed)
        }
        let cell = addressDetailsCell(address: info.address,
                                      name: keyInfo?.displayName ?? name,
                                      indexPath: indexPath,
                                      badgeName: keyInfo?.keyType.badgeName,
                                      browseURL: browseUrl,
                                      prefix: safe.chain!.shortName,
                                      showAccessoryImage: keyInfo != nil)
        cell.selectionStyle = .none

        return cell
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
                    [weak self] _, _, completion in
                    self?.remove(owner: info.address, prevOwner: prevOwner?.address)
                    completion(true)
                }
                removeOwnerAction.backgroundColor = .error

                actions.append(removeOwnerAction)
            }

            let replaceAction = UIContextualAction(style: .normal, title: "Replace") {
                [weak self] _, _, completion in
                self?.replace(owner: info.address, prevOwner: prevOwner?.address)
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
        addOwnerFlow = AddOwnerFlowFromSettings(safe: safe!) { [weak self] _ in
            self?.addOwnerFlow = nil
        }
        present(flow: addOwnerFlow)
        Tracker.trackEvent(.addOwnerFromSettings)
    }

    func replace(owner: Address, prevOwner: Address?) {
        replaceOwnerFlow = ReplaceOwnerFromSettingsFlow(
            ownerToReplace: owner,
            prevOwner: prevOwner,
            safe: safe!
        ) { [weak self] _ in
            self?.replaceOwnerFlow = nil
        }
        present(flow: replaceOwnerFlow)
        Tracker.trackEvent(.replaceOwnerFromSettings)
    }

    func remove(owner: Address, prevOwner: Address?) {
        removeOwnerFlow = RemoveOwnerFlow(owner: owner, prevOwner: prevOwner, safe: safe!) { [weak self] _ in
            self?.removeOwnerFlow = nil
        }
        present(flow: removeOwnerFlow)
        Tracker.trackEvent(.userRemoveOwnerFromSettings)
    }

    private func addressDetailsCell(address: Address,
                                    name: String?,
                                    indexPath: IndexPath,
                                    badgeName: String? = nil,
                                    browseURL: URL? = nil,
                                    prefix: String? = nil,
                                    showAccessoryImage: Bool = false) -> DetailAccountCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        let keyInfo = try? KeyInfo.keys(addresses: [address]).first
        let copyEnabled = keyInfo == nil
        cell.setAccount(address: address,
                        label: name,
                        badgeName: badgeName,
                        copyEnabled: copyEnabled,
                        browseURL: browseURL,
                        prefix: prefix,
                        showAccessoryImage: showAccessoryImage)

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

        case Section.RequiredConfirmations.confirmations(_):
            changeConfirmationsFlow = ChangeConfirmationsFlow(safe: safe) { [weak self] _ in
                self?.changeConfirmationsFlow = nil
            }

            guard changeConfirmationsFlow != nil else {
                return
            }

            present(flow: changeConfirmationsFlow)
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
        case Section.Status.status:
            return UITableView.automaticDimension
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

        case Section.requiredConfirmations(let name):
            view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            (view as! BasicHeaderView).setName(name)

        case Section.ownerAddresses(let name):
            view = tableView.dequeueHeaderFooterView(OwnerHeaderView.self)
            let ownerHeaderView = view as! OwnerHeaderView
            ownerHeaderView.setName(name)
            ownerHeaderView.setNumber(safe.ownersInfo?.count)
            ownerHeaderView.addButton.isHidden = safe.isReadOnly

            ownerHeaderView.onAdd = { [weak self] in
                Tracker.trackEvent(.addOwnerFromSettings)
                self?.addOwner()
            }
        default:
            break
        }

        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isValid(section: section), let _ = safe else {
            return nil
        }

        let section = sections[section].section
        var view: InfoTableFooterView?
        switch section {
        case Section.requiredConfirmations(_):
            view = tableView.dequeueHeaderFooterView(InfoTableFooterView.self)
            view!.titleLabel.text = "Use a threshold higher than one to prevent losing access to your Safe Account. Also, keep it lower than the total number of owners."

        case Section.ownerAddresses(_):
            view = tableView.dequeueHeaderFooterView(InfoTableFooterView.self)
            view!.titleLabel.text = "We recommend to add more than 1 owner."
        default:
            break
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard isValid(section: section) else {
            return 0
        }

        let section = sections[section].section

        switch section {
        case Section.requiredConfirmations(_):
            return BasicHeaderView.headerHeight

        case Section.ownerAddresses(_):
            return BasicHeaderView.headerHeight
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard isValid(section: section) else {
            return 0
        }

        let section = sections[section].section

        switch section {
        case Section.requiredConfirmations(_):
            return UITableView.automaticDimension

        case Section.ownerAddresses(_):
            return UITableView.automaticDimension
        default:
            return 0
        }
    }
}
