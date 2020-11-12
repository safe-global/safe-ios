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
    private var lastError: Error?

    enum Section {
        case name(String)
        case requiredConfirmations(String)
        case ownerAddresses(String)
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

        enum Advanced: SectionItem {
            case advanced(String)
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
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(AddressDetailsCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        // update all safe info on changing safe name
        notificationCenter.addObserver(
            self, selector: #selector(didChangeSafe), name: .selectedSafeUpdated, object: nil)
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
                        self.lastError = error
                        self.onError()
                    }
                case .success(let safeInfo):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.updateSections(with: safeInfo)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            lastError = error
            onError()
        }
    }

    private func updateSections(with info: SafeStatusRequest.Response) {
        sections = [
            (section: .name("Name"), items: [Section.Name.name(safe.name!)]),
            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(info.threshold) out of \(info.owners.count)")]),
            (section: .ownerAddresses("Owner addresses"),
             items: info.owners.map { Section.OwnerAddresses.owner($0.description) }),
            (section: .advanced, items: [Section.Advanced.advanced("Advanced")])
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
        case Section.Advanced.advanced(let name):
            return basicCell(name: name, indexPath: indexPath)
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
        let cell = tableView.dequeueCell(AddressDetailsCell.self, for: indexPath)
        cell.setAddress(Address(exactly: address))
        cell.setStyle(.address)
        cell.selectionStyle = .none
        cell.onViewDetails = { [unowned self] in
            self.openInSafari(Safe.browserURL(address: address))
        }
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(_):
            // This will be reworked with UIKit implementation as there is a glitch with navigation controller
            let hostedView = EditSafeNameView(address: safe.address ?? "", name: safe.name ?? "")
            let hostingController = UIHostingController(rootView: hostedView)
            show(hostingController, sender: self)
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
            return AddressDetailsCell.rowHeight
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
