//
//  ClaimingAmountViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class ClaimingAmountViewController: LoadableViewController {
    enum RowItem {
        case claimable
        case claimingAmount
    }

    private var guardian: Guardian!
    private var safe: Safe!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 3
    private var onClaim: ((Guardian, String) -> ())?
    private var claimingAmount: SafeClaimingAmount!

    private var stepLabel: UILabel!

    var rows: [RowItem] = [.claimable, .claimingAmount]
    private let tokenFormatter = TokenFormatter()

    convenience init(stepNumber: Int = 2,
                     maxSteps: Int = 3,
                     guardian: Guardian,
                     safe: Safe,
                     onClaim: @escaping (Guardian, String) -> ()) {
        self.init(namedClass: Self.superclass())
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onClaim = onClaim
        self.guardian = guardian
        self.safe = safe
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        claimingAmount = SafeClaimingController.shared.claimingAmountFor(safe: safe.addressValue)
        assert(claimingAmount != nil)

        tableView.registerCell(AvailableClaimingAmountTableViewCell.self)
        tableView.registerCell(EnterClaimingAmountTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
        navigationItem.title = "Safe Token Claiming"
    }

    override func reloadData() {

    }
}

extension ClaimingAmountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .claimable:
            let cell = tableView.dequeueCell(AvailableClaimingAmountTableViewCell.self)

            cell.set(claimableNowUserAirdropValue: tokenFormatter.string(from: claimingAmount.userAmount.now),
                     claimableNowEcosystemAirdropValue: tokenFormatter.string(from: claimingAmount.ecosystemAmount.now),
                     claimableNowTotal: tokenFormatter.string(from: claimingAmount.totalClaimable),
                     claimableInFutureUserAirdropValue: tokenFormatter.string(from: claimingAmount.userAmount.future),
                     claimableInFutureEcosystemAirdropValue: tokenFormatter.string(from: claimingAmount.ecosystemAmount.future),
                     claimableInFutureTotal: tokenFormatter.string(from: claimingAmount.totalClaimableInFuture))
            return cell
        case .claimingAmount:
            let cell = tableView.dequeueCell(EnterClaimingAmountTableViewCell.self)
            cell.set(value: "0",
                     maxValue: tokenFormatter.string(from: claimingAmount.totalClaimable),
                     guardian: guardian) { [unowned self] claimingValue in
                onClaim?(guardian, claimingValue)
            }
            return cell
        }
    }
}
