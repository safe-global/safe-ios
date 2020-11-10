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
        case advanced

        enum Name: SectionItem {
            case name(String)
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
        tableView.rowHeight = BasicCell.rowHeight
        tableView.separatorStyle = .none
        tableView.registerCell(BasicCell.self)
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
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        case Section.Advanced.advanced(let name):
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        default:
            return UITableViewCell()
        }
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        if case Section.name(let name) = section {
            view.setName(name)
        } else if case Section.advanced = section {
            view.setName("")
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
