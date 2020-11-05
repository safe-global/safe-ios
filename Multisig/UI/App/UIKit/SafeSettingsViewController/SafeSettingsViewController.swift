//
//  SafeSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class SafeSettingsViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var safeTransactionService = App.shared.safeTransactionService
    let tableBackgroundColor: UIColor = .gnoWhite
    let rowHeight: CGFloat = 60

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var currentDataTask: URLSessionTask?
    private var sections = [SectionItems]()
    private var lastError: Error?

    enum Section: String {
        case name = "Safe Name"
        case advanced = ""

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
        tableView.rowHeight = rowHeight
        tableView.separatorStyle = .none
        tableView.registerCell(BasicCell.self)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            let safe = try Safe.getSelected()!
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
                        self.updateSections(with: safeInfo, safe: safe)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            lastError = error
            onError()
        }
    }

    private func updateSections(with info: SafeStatusRequest.Response, safe: Safe) {
        sections = [
            (section: .name, items: [Section.Name.name(safe.name!)]),
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
        if case Section.Name.name(let name) = item {
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        } else if case Section.Advanced.advanced(let name) = item {
            let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
            cell.setTitle(name)
            return cell
        }
        return UITableViewCell()
    }
}
