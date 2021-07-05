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
    var networkId: Int!

    convenience init(transactions: [Transaction], addressInfoIndex: AddressInfoIndex?, networkId: Int) {
        self.init()
        self.transactions = transactions
        self.addressInfoIndex = addressInfoIndex
        self.networkId = networkId
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

        let (name, imageUri) = displayNameAndImageUri(
            address: tx.to, addressInfoIndex: addressInfoIndex, networkId: networkId)

        cell.setAddress(tx.to.address, label: name, imageUri: imageUri)
        cell.setAction(tx.dataDecoded?.method ?? "Action #\(indexPath.row + 1)")
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = transactions[indexPath.row]
        let vc = ActionDetailViewController(tx: tx,
                                            addressInfoIndex: addressInfoIndex,
                                            networkId: networkId,
                                            placeholderTitle: "Action #\(indexPath.row + 1)")
        show(vc, sender: self)
    }
}
