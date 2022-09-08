//
//  MultiSendListTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MultiSendListTableViewController: UITableViewController {
    typealias MultiSendTx = SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    typealias AddressInfoIndex = SCGModels.AddressInfoIndex

    var transactions: [MultiSendTx] = []
    var addressInfoIndex: AddressInfoIndex?
    var chain: Chain!

    convenience init(transactions: [MultiSendTx], addressInfoIndex: AddressInfoIndex?, chain: Chain) {
        self.init()
        self.transactions = transactions
        self.addressInfoIndex = addressInfoIndex
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Multisend"

        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCell(MultiSendRowTableViewCell.self)
        tableView.backgroundColor = .backgroundSecondary

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .addressbookChanged,
                             .selectedSafeChanged,
                             .selectedSafeUpdated,
                             .chainInfoChanged] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionDetailsActionList)
    }

    @objc func lazyReloadData() {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MultiSendRowTableViewCell.self, for: indexPath)
        let tx = transactions[indexPath.row]

        let (name, imageUri) = NamingPolicy.name(for: tx.to.address,
                                                    info: addressInfoIndex?.values[tx.to]?.addressInfo,
                                                    chainId: chain.id!)

        cell.setAddress(tx.to.address,
                        label: name,
                        imageUri: imageUri,
                        prefix: chain.shortName)
        cell.setAction(tx.dataDecoded?.method ?? "Action #\(indexPath.row + 1)")
        let untrusted = DelegateWarningCalculator.isUntrusted(multiSendTx: tx, addressInfoIndex: addressInfoIndex)
        cell.setDelegateWarning(untrusted)
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = transactions[indexPath.row]
        let root = ActionDetailViewController(
            tx: tx,
            addressInfoIndex: addressInfoIndex,
            chain: chain,
            placeholderTitle: "Action #\(indexPath.row + 1)")
        let vc = RibbonViewController(rootViewController: root)
        show(vc, sender: self)
    }
}
