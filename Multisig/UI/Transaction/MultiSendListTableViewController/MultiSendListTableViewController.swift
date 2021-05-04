//
//  MultiSendListTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MultiSendListTableViewController: UITableViewController {

    typealias Transaction = SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    typealias AddressInfoIndex = SCGModels.AddressInfoIndex

    var transactions: [Transaction] = []
    var addressInfoIndex: AddressInfoIndex?

    convenience init(transactions: [Transaction], addressInfoIndex: AddressInfoIndex?) {
        self.init()
        self.transactions = transactions
        self.addressInfoIndex = addressInfoIndex
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Multisend"
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCell(MultiSendRowTableViewCell.self)
        tableView.backgroundColor = .secondaryBackground
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

        let address = tx.to.address
        var label: String?
        var imageUri: URL?
        if let knownAddress = addressInfoIndex?.values[AddressString(address)] {
            label = knownAddress.name
            imageUri = knownAddress.logoUri
        }
        cell.setAddress(tx.to.address, label: label, imageUri: imageUri)
        cell.setAction(tx.dataDecoded?.method ?? "Action #\(indexPath.row + 1)")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = transactions[indexPath.row]
        let vc = ActionDetailViewController(tx: tx, placeholderTitle: "Action #\(indexPath.row + 1)")
        show(vc, sender: self)
    }
}
