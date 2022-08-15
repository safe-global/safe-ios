//
//  ChooseGuardianViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseGuardianViewController: LoadableViewController {
    private var currentDataTask: URLSessionTask?
    private enum Section {
        case guardiansCount(count: Int)
        case guardians(items: [Guardian])
    }

    private var sections: [Section] = []

    private var stepLabel: UILabel!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 3

    private var guardians: [Guardian] = []
    private var filteredGuardians: [Guardian] = []

    var onSelected: ((Guardian) -> ())?
    var onReloaded: (() -> ())?

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.makeTransparentNavigationBar(self)
        navigationItem.hidesBackButton = false

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        tableView.registerCell(GuardianTableViewCell.self)
        tableView.registerCell(GuardianCountTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorStyle = .none

        emptyView.setText("No delegates were found. Try to search again or use a custom address.")
        emptyView.setImage(UIImage(named: "ico-delegate-placeholder")!)
    }

    private func makeSections(items: [Guardian]) -> [Section] {
        guard !items.isEmpty else { return [] }

        var sections = [Section]()

        sections.append(.guardiansCount(count: items.count))
        sections.append(.guardians(items: items))

        return sections
    }

    func filterData(searchTerm: String) {
        let searchTerm = searchTerm.lowercased()
        if !searchTerm.isEmpty {
            filteredGuardians = guardians.filter { guardian in
                return guardian.name?.lowercased().contains(searchTerm) ?? false ||
                guardian.ens?.lowercased().contains(searchTerm) ?? false ||
                guardian.address.description.lowercased().contains(searchTerm)
            }

        } else {
            filteredGuardians = guardians
        }
        sections = makeSections(items: filteredGuardians)
        if isEmpty {
            showOnly(view: emptyView)
        } else {
            showOnly(view: tableView)
        }
        tableView.reloadData()
    }

    override var isEmpty: Bool { sections.isEmpty }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        currentDataTask = App.shared.claimingService.asyncGuardians() { [weak self] result in
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

                    self.onError(GSError.error(description: "Failed to load guardians", error: error))
                    self.onReloaded?()
                }
            case .success(let results):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.guardians = results
                    self.filteredGuardians = results
                    self.sections = self.makeSections(items: self.filteredGuardians)
                    self.onSuccess()
                }
            }
        }
    }
}

extension ChooseGuardianViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
       sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .guardiansCount: return 1
        case .guardians(items: let items): return items.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch sections[indexPath.section] {

        case .guardiansCount(count: let count):
            let cell = tableView.dequeueCell(GuardianCountTableViewCell.self)
            cell.setCount(count)
            return cell

        case .guardians(items: let items):
            let cell = tableView.dequeueCell(GuardianTableViewCell.self)
            cell.set(guardian: items[indexPath.row])
            cell.tableView = tableView
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch sections[indexPath.section] {

        case .guardians(items: let items):
            let item = items[indexPath.row]
            let vc = GuardianDetailsViewController()
            vc.onSelected = onSelected
            vc.guardian = item
            show(vc, sender: nil)
            break

        default: break
        }
    }
}


