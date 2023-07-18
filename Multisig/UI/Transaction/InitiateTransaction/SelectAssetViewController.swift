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
    
    private let tableBackgroundColor: UIColor = .backgroundPrimary

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
        navigationItem.backButtonTitle = "Back"
        
        tableView.registerCell(BalanceTableViewCell.self)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil
        
        emptyView.setImage(UIImage(named: "ico-no-assets")!)
        emptyView.setTitle("No assets found.")
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
    
    @objc override func willEnterForeground() {
        onSuccess()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transferFundsVC = TransactionViewController()
        let ribbon = RibbonViewController(rootViewController: transferFundsVC)
        transferFundsVC.tokenBalance = filteredBalances[indexPath.row]
        show(ribbon, sender: self)
    }
}

extension SelectAssetViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let inverseSet = CharacterSet(charactersIn:"0123456789").inverted

        let components = string.components(separatedBy: inverseSet)

        let filtered = components.joined(separator: "")

        if filtered == string {
            return true
        } else {
            if string == "." {
                let countdots = textField.text!.components(separatedBy:".").count - 1
                if countdots == 0 {
                    return true
                }else{
                    if countdots > 0 && string == "." {
                        return false
                    } else {
                        return true
                    }
                }
            }else{
                return false
            }
        }
    }
}
