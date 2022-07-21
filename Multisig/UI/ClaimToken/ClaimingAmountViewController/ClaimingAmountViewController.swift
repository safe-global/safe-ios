//
//  ClaimingAmountViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimingAmountViewController: LoadableViewController {
    enum RowItem {
        case claimable
        case claimingAmount
    }

    private var guardian: Guardian!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 3
    private var onClaim: (() -> ())?

    private var stepLabel: UILabel!

    var rows: [RowItem] = [.claimable, .claimingAmount]

    convenience init(stepNumber: Int = 2,
                     maxSteps: Int = 3,
                     guardian: Guardian,
                     onClaim: @escaping () -> ()) {
        self.init(namedClass: Self.superclass())
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onClaim = onClaim
        self.guardian = guardian
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
            cell.set(claimableNowUserAirdropValue: "109.92",
                     claimableNowEcosystemAirdropValue: "19.46",
                     claimableNowTotal: "129.38",
                     claimableInFutureUserAirdropValue: "109.92",
                     claimableInFutureEcosystemAirdropValue: "19.46",
                     claimableInFutureTotal: "129.38")
            return cell
        case .claimingAmount:
            let cell = tableView.dequeueCell(EnterClaimingAmountTableViewCell.self)
            cell.set(value: "0", maxValue: "129.38", guardian: guardian) { [unowned self] claimingValue in
                onClaim?()
            }
            return cell
        }
    }
}
