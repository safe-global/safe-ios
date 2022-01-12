//
//  ReviewExecutionContentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewExecutionContentViewController: UITableViewController {

    typealias Transaction = SCGModels.TransactionDetails

    private var safe: Safe!
    private var chain: Chain!
    private var transaction: SCGModels.TransactionDetails!

    private var builder: TransactionDetailCellBuilder!

    private var cells: [UITableViewCell] = []

    convenience init(safe: Safe, chain: Chain, transaction: Transaction) {
        self.init(nibName: nil, bundle: nil)

        self.safe = safe
        self.chain = chain
        self.transaction = transaction
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)
        assert(chain != nil)
        assert(transaction != nil)

        builder = ReviewExecutionCellBuilder(
            vc: self,
            tableView: tableView,
            chain: chain
        )

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        tableView.allowsSelection = false

        // TODO: handling app notifications
            // owner key imported, removed, updated - for selecting keys
            // chain info changed - for execution options and policies
            // address book changed - for displaying names
            // selected safe updated or changed? - for safe address

        // build everything
        reloadData()
    }

    // pull to refresh? - not now

    func reloadData() {
        cells = builder.build(transaction)
        tableView.reloadData()
    }

    // MARK: UITableView delegate and data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

}
