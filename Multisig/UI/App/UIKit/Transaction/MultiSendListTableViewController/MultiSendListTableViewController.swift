//
//  MultiSendListTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MultiSendListTableViewController: UITableViewController {

    typealias Transaction = SCG.DataDecoded.Parameter.ValueDecoded.MultiSendTx

    var transactions: [Transaction] = [] {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }

    convenience init(_ txes: [Transaction]) {
        self.init()
        self.transactions = txes
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Multisend"
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCell(MultiSendRowTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.transactionDetailsActionList)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MultiSendRowTableViewCell.self, for: indexPath)
        let tx = transactions[indexPath.row]
        cell.setIdenticon(tx.to.address.hexadecimal)
        cell.setMainText(tx.to.address.ellipsized())
        cell.setAction(tx.dataDecoded?.method ?? "Action #\(indexPath.row + 1)")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // open action view
    }
}
