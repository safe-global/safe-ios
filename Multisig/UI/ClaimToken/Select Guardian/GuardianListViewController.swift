//
//  GuardianListViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit


class GuardianListViewController: LoadableViewController {
    private var currentDataTask: URLSessionTask?
    private enum Section {
        case guardiansCount(count: Int)
        case guardians(items: [Guardian])
    }

    private var sections: [Section] = []

    private var guardians: [Guardian] = []

    var onSelected: ((Guardian) -> ())?
    var onReloaded: (() -> ())?

    private var searchController: UISearchController!
    private var resultsController: GuardianSearchResultController!

    var controller: ClaimingAppController!
    var safe: Safe!
    var selectedDelegate: Address?

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.removeNavigationBarBorder(self)
        title = "Choose a delegate"

        resultsController = GuardianSearchResultController()

        resultsController.tableView.delegate = self

        searchController = UISearchController(searchResultsController: resultsController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Name, address or ENS"
        searchController.hidesNavigationBarDuringPresentation = false
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.registerCell(GuardianTableViewCell.self)
        tableView.registerCell(GuardianCountTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorStyle = .none

        // Empty view is never shown. Instead the list is empty, when no results are found
        emptyView.setTitle("No delegates were found. Try to search again or use a custom address.")
        emptyView.setImage(UIImage(named: "ico-delegate-placeholder")!)
        extendedLayoutIncludesOpaqueBars = true
    }

    private func makeSections(items: [Guardian]) -> [Section] {
        guard !items.isEmpty else {
            return []
        }

        var sections = [Section]()

        sections.append(.guardiansCount(count: items.count))
        sections.append(.guardians(items: items))

        return sections
    }

    override var isEmpty: Bool { sections.isEmpty }

    override func reloadData() {
        super.reloadData()

        controller.guardians(for: safe.addressValue) { [weak self] result in
            guard let `self` = self else { return }
            do {
                let data = try result.get()
                self.selectedDelegate = data.delegate

                if let selectedIndex = data.guardians.firstIndex(where: { $0.address.address == data.delegate }) {
                    var results = data.guardians
                    let selected = results.remove(at: selectedIndex)
                    results = results.shuffled()
                    results.insert(selected, at: 0)
                    self.guardians = results
                } else {
                    self.guardians = data.guardians.shuffled()
                }

                self.sections = self.makeSections(items: self.guardians)
                self.onSuccess()
            } catch {
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }

                self.onError(GSError.error(description: "Failed to load guardians", error: error))
                self.onReloaded?()
            }
        }
    }
}

extension GuardianListViewController: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {

    func updateSearchResults(for searchController: UISearchController) {
        guard let resultsController = searchController.searchResultsController as? GuardianSearchResultController else {
            return
        }
        if !searchController.searchBar.text!.isEmpty {
            Tracker.trackEvent(.userClaimChdelSearch)
        }
        let terms = searchController.searchBar.text!
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ") as [String]

        resultsController.filteredGuardians = guardians.filter { guardian in
            // all terms AND with each other
            let allMatch = terms.allSatisfy { term in
                // - each tearm is OR of 'contains' name, address, ens
                // - using comparison that is case-insensitive, and diacritic-insensitive
                guardian.name?.localizedStandardContains(term) == true ||
                guardian.address.description.localizedStandardContains(term) ||
                guardian.ens?.localizedStandardContains(term) == true
            }

            return allMatch
        }
        resultsController.selectedDelegate = selectedDelegate
        resultsController.tableView.reloadData()
        if !searchController.searchBar.text!.isEmpty && resultsController.filteredGuardians.isEmpty {
                Tracker.trackEvent(.screenClaimChdelNf)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension GuardianListViewController: UITableViewDelegate, UITableViewDataSource {

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
            let item = items[indexPath.row]
            cell.set(guardian: item, selected: item.address.address == selectedDelegate)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = self.item(at: indexPath) else { return }
        let vc = GuardianDetailsViewController()
        vc.onSelected = onSelected
        vc.guardian = item
        show(vc, sender: nil)
    }

    func item(at indexPath: IndexPath) -> Guardian? {
        if searchController.isActive && searchController.showsSearchResultsController {
            return resultsController.filteredGuardians[indexPath.row]
        }
        switch sections[indexPath.section] {

        case .guardians(items: let items):
            let item = items[indexPath.row]
            return item

        default: break
        }

        return nil
    }
}


class GuardianSearchResultController: UITableViewController {
    var filteredGuardians: [Guardian] = []
    var selectedDelegate: Address?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(GuardianTableViewCell.self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredGuardians.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(GuardianTableViewCell.self)
        let item = filteredGuardians[indexPath.row]
        cell.set(guardian: item, selected: item.address.address == selectedDelegate)
        return cell
    }
}
