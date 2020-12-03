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
    var safeTransactionService = App.shared.safeTransactionService
    let tableBackgroundColor: UIColor = .gnoWhite
    let advancedSectionHeaderHeight: CGFloat = 28

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var currentDataTask: URLSessionTask?
    private var sections = [SectionItems]()
    private var safe: Safe!
    private var ensLoader: ENSNameLoader!

    enum Section {
        case name(String)
        case requiredConfirmations(String)
        case ownerAddresses(String)
        case contractVersion(String)
        case ensName(String)
        case advanced

        enum Name: SectionItem {
            case name(String)
        }

        enum RequiredConfirmations: SectionItem {
            case confirmations(String)
        }

        enum OwnerAddresses: SectionItem {
            case owner(String)
        }

        enum ContractVersion: SectionItem {
            case contractVersion(String)
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
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(ContractVersionStatusCell.self)
        tableView.registerCell(LoadingValueCell.self)
        tableView.registerCell(RemoveSafeCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        // update all safe info on changing safe name
        notificationCenter.addObserver(
            self, selector: #selector(didChangeSafe), name: .selectedSafeUpdated, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsSafe)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            safe = try Safe.getSelected()!
            let address = try Address(from: safe.address!)
            currentDataTask = safeTransactionService.asyncSafeInfo(at: address) { [weak self] result in
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
                        self.onError(error)
                    }
                case .success(let safeInfo):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.safe.update(from: safeInfo)
                        self.updateSections(with: safeInfo)
                        self.ensLoader = ENSNameLoader(safe: self.safe, delegate: self)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(error)
        }
    }

    private func updateSections(with info: SafeStatusRequest.Response) {
        sections = [
            (section: .name("Name"), items: [Section.Name.name(safe.name!)]),

            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(info.threshold) out of \(info.owners.count)")]),

            (section: .ownerAddresses("Owner addresses"),
             items: info.owners.map { Section.OwnerAddresses.owner($0.description) }),

            (section: .contractVersion("Contract version"),
             items: [Section.ContractVersion.contractVersion(info.implementation.description)]),

            (section: .ensName("ENS name"), items: [Section.EnsName.ensName]),

            (section: .advanced, items: [
                Section.Advanced.advanced("Advanced"),
                Section.Advanced.removeSafe])
        ]
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.RequiredConfirmations.confirmations(let name):
            return basicCell(name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        case Section.OwnerAddresses.owner(let name):
            return addressDetailsCell(address: name, indexPath: indexPath)

        case Section.ContractVersion.contractVersion(let version):
            return contractVersionCell(version: version, indexPath: indexPath)

        case Section.EnsName.ensName:
            if ensLoader.isLoading {
                return loadingCell(name: nil, indexPath: indexPath)
            } else {
                return loadingCell(name: safe.ensName ?? "Reverse record not set", indexPath: indexPath)
            }

        case Section.Advanced.advanced(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.Advanced.removeSafe:
            return removeSafeCell(indexPath: indexPath)

        default:
            return UITableViewCell()
        }
    }

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

    private func addressDetailsCell(address: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(addressInfo: AddressInfo(address: Address(exactly: address), label: nil), title: nil)
        cell.selectionStyle = .none
        cell.onViewDetails = { [unowned self] in
            self.openInSafari(Safe.browserURL(address: address))
        }
        return cell
    }

    private func contractVersionCell(version: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ContractVersionStatusCell.self, for: indexPath)
        cell.setAddress(Address(exactly: version))
        cell.selectionStyle = .none
        cell.onViewDetails = { [unowned self] in
            self.openInSafari(Safe.browserURL(address: version))
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

    private func removeSafeCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(RemoveSafeCell.self, for: indexPath)
        cell.onRemove = { [unowned self] in
            let alertController = UIAlertController(
                title: nil,
                message: "Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost.",
                preferredStyle: .actionSheet)
            let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
                Safe.remove(safe: self.safe)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(remove)
            alertController.addAction(cancel)
            self.present(alertController, animated: true)
        }
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(_):
            let vc = ViewControllerFactory.editSafeNameController(address: safe.address, name: safe.name, presenter: self)
            present(vc, animated: true, completion: nil)
        case Section.Advanced.advanced(_):
            let hostedView = AdvancedSafeSettingsView(safe: safe)
            let hostingController = UIHostingController(rootView: hostedView)
            show(hostingController, sender: self)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.OwnerAddresses.owner(_):
            return UITableView.automaticDimension

        case Section.ContractVersion.contractVersion(_):
            return UITableView.automaticDimension

        case Section.EnsName.ensName:
            return LoadingValueCell.rowHeight

        case Section.Advanced.removeSafe:
            return RemoveSafeCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.name(let name):
            view.setName(name)

        case Section.requiredConfirmations(let name):
            view.setName(name)

        case Section.ownerAddresses(let name):
            view.setName(name)

        case Section.contractVersion(let name):
            view.setName(name)

        case Section.ensName(let name):
            view.setName(name)

        case Section.advanced:
            break
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        if case Section.advanced = section {
            return advancedSectionHeaderHeight
        }
        return BasicHeaderView.headerHeight
    }
}

extension SafeSettingsViewController: ENSNameLoaderDelegate {
    func ensNameLoaderDidLoadName(_ loader: ENSNameLoader) {
        tableView.reloadData()
    }
}
