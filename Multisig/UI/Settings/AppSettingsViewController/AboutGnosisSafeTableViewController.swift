//
//  AboutGnosisSafeTableViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 08.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit


class AboutGnosisSafeTableViewController: UITableViewController {
    
    var legal = App.configuration.legal
    
    enum Item {
        case terms(String)
        case privacyPolicy(String)
        case licenses(String)
        case rateTheApp(String)
    }
    
    private var items: [Item] = [
        .terms("Terms of use"),
        .privacyPolicy("Privacy policy"),
        .licenses("Licenses"),
        .rateTheApp("Rate the app")
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "About Gnosis Safe"
        
        tableView.registerCell(BasicCell.self)
        
        tableView.backgroundColor = .primaryBackground
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = items[indexPath.row]
        
        switch item {
        case Item.terms(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.privacyPolicy(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.licenses(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.rateTheApp(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        switch item {
        case Item.terms:
            openInSafari(legal.termsURL)
    
        case Item.privacyPolicy:
            openInSafari(legal.privacyURL)

        case Item.licenses:
            openInSafari(legal.licensesURL)

        case Item.rateTheApp:
            let url = App.configuration.contact.appStoreReviewURL
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
