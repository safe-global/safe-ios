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
    var onTapPaymentMethod: () -> Void = {}
    var onTapAccount: () -> Void = {}
    var onTapFee: () -> Void = {}
    var onTapAdvanced: () -> Void = {}
    var onReload: () -> Void = {}

    var model: ExecutionReviewUIModel? {
        didSet {
            guard isViewLoaded else { return }
            reloadData()
        }
    }

    private var safe: Safe!
    private var chain: Chain!
    private var transaction: SCGModels.TransactionDetails!
    private var pullToRefreshControl: UIRefreshControl!

    private var builder: ReviewExecutionCellBuilder!

    private var cells: [UITableViewCell] = []

    convenience init(safe: Safe, chain: Chain, transaction: Transaction) {
        self.init(nibName: nil, bundle: nil)

        self.safe = safe
        self.chain = chain
        self.transaction = transaction
    }

    var userSelectedSigner: Bool {
        set {
            builder.userSelectedSigner = newValue
        }
        get {
            builder.userSelectedSigner
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)
        assert(chain != nil)
        assert(transaction != nil)

        builder = ReviewExecutionCellBuilder(
            vc: self.parent ?? self,
            tableView: tableView,
            chain: chain,
            safe: safe
        )
        builder.onTapPaymentMethod = onTapPaymentMethod
        builder.onTapAccount = onTapAccount
        builder.onTapFee = onTapFee
        builder.onTapAdvanced = onTapAdvanced

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        pullToRefreshControl = UIRefreshControl()
        pullToRefreshControl.addTarget(self,
                                       action: #selector(pullToRefreshChanged),
                                       for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
        tableView.backgroundColor = .backgroundSecondary

        // build everything
        reloadData()
    }

    @objc private func pullToRefreshChanged() {
        onReload()
    }

    func didEndReloading() {
        pullToRefreshControl.endRefreshing()
    }

    func reloadData() {
        guard let model = model else { return }
        cells = builder.build(model)
        tableView.reloadData()
    }

    // MARK: UITableView delegate and data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if let disclosureCell = cell as? DetailDisclosingCell {
            disclosureCell.action()
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        return cell is DetailDisclosingCell ? indexPath : nil
    }
}
