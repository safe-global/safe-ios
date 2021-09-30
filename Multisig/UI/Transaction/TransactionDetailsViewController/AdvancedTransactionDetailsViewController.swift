//
//  AdvancedTransactionDetailsViewController.swift
//  Multisig
//
//  Created by Moaaz on 9/29/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AdvancedTransactionDetailsViewController: UITableViewController {
    var items:[(title: String, value: Any)] = []
    let namingPolicy = DefaultAddressNamingPolicy()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetailsAdvanced)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Advanced"

        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        if let addressInfo = item.value as? SCGModels.AddressInfo {
            let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
            cell.setAccount(address: addressInfo.value.address, label: addressInfo.name, title: item.title, imageUri: addressInfo.logoUri)
            return cell
        } else if let string = item.value as? String {
            let cell = tableView.dequeueCell(DetailExpandableTextCell.self, for: indexPath)
            cell.setTitle(item.title)
            cell.setCopyText(string)
            cell.setText(string)
            cell.setExpandableTitle(nil)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
