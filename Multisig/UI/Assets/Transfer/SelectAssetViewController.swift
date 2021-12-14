//
//  SelectAssetViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 09.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectAssetViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var term: String = ""
    
    var balances: [TokenBalance] = []
    
    var filteredBalances: [TokenBalance] = []
    
    override var isEmpty: Bool { filteredBalances.isEmpty }
    
    private let tableBackgroundColor: UIColor = .primaryBackground

    convenience init(balances: [TokenBalance]) {
        self.init(namedClass: Self.superclass())
        self.balances = balances
        self.filteredBalances = balances
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        term = searchController.searchBar.text?.lowercased() ?? ""
        if !term.isEmpty {
            filteredBalances = balances.filter { balance in
                return balance.symbol.lowercased().contains(term) || balance.name.lowercased().contains(term)
            }
        } else {
            filteredBalances = balances
        }
        if isEmpty {
            showOnly(view: emptyView)
        } else {
            showOnly(view: tableView)
        }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select an asset"
        navigationItem.searchController = searchController
        
        tableView.registerCell(BalanceTableViewCell.self)
        
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil
        
        emptyView.setImage(UIImage(named: "ico-no-assets")!)
        emptyView.setText("No assets found.")
        emptyView.refreshControl = nil
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onSuccess()
        Tracker.trackEvent(.assetsTransferSelect)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredBalances.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filteredBalances[indexPath.row]
        let cell = tableView.dequeueCell(BalanceTableViewCell.self, for: indexPath)
        cell.setMainText(item.symbol)
        cell.setDetailText(item.balance)
        cell.setSubDetailText(item.fiatBalance)
        if let image = item.image {
            cell.setImage(image)
        } else {
            cell.setImage(with: item.imageURL, placeholder: UIImage(named: "ico-token-placeholder")!)
        }
        return cell
    }
}
