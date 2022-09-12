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
        case guardiansCount
        case guardians
    }

    private var sections: [Section] = []

    private var guardians: [Guardian] = []
    var filteredGuardians: [Guardian] = []

    var onSelected: ((Guardian) -> ())?
    var onReloaded: (() -> ())?

    private var searchController: UISearchController!

    var controller: ClaimingAppController!
    var safe: Safe!
    var selectedDelegate: Address?

    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }

    var isFiltering: Bool {
        searchController.isActive && !isSearchBarEmpty
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.removeNavigationBarBorder(self)
        title = "Choose a delegate"

        searchController = UISearchController(searchResultsController:  nil)
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

        emptyView.setText("No delegates were found. Try to search again or use a custom address.")
        emptyView.setImage(UIImage(named: "ico-delegate-placeholder")!)
    }

    private func makeSections(items: [Guardian]) {
        self.sections = []
        guard !items.isEmpty else { return }

        var sections = [Section]()

        if !isFiltering {
            sections.append(.guardiansCount)
        }

        sections.append(.guardians)

        self.sections = sections
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

                self.makeSections(items: self.guardians)
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
        if !isSearchBarEmpty {
            Tracker.trackEvent(.userClaimChdelSearch)

        } else if !isSearchBarEmpty && filteredGuardians.isEmpty {
            Tracker.trackEvent(.screenClaimChdelNf)
        }

        let terms = searchController.searchBar.text!
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ") as [String]

        filterContentForSearchText(terms)
        makeSections(items: isFiltering ? filteredGuardians : guardians)
        onSuccess()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func filterContentForSearchText(_ terms: [String]) {
        filteredGuardians = guardians.filter { guardian in
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
    }

}

extension GuardianListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
       sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .guardiansCount: return 1
        case .guardians:
            if isFiltering {
                return filteredGuardians.count
            }

            return guardians.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {

        case .guardiansCount:
            let cell = tableView.dequeueCell(GuardianCountTableViewCell.self)
            cell.setCount(isFiltering ? filteredGuardians.count : guardians.count)
            return cell

        case .guardians:
            let cell = tableView.dequeueCell(GuardianTableViewCell.self)
            let item = item(at: indexPath.row)
            cell.set(guardian: item, selected: item.address.address == selectedDelegate)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = GuardianDetailsViewController()
        vc.onSelected = onSelected
        vc.guardian = item(at: indexPath.row)
        show(vc, sender: nil)
    }

    func item(at index: Int) -> Guardian {
        isFiltering ? filteredGuardians[index] : guardians[index]
    }
}
