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
        case claimableNow
        case claimableFuture
        case claimableTotal
        case claimingAmount
    }

    private var guardian: Guardian!
    private var safe: Safe!
    private var stepNumber: Int = 3
    private var maxSteps: Int = 4
    private var onClaim: ((Guardian, String) -> ())?
    private var claimingAmount: SafeClaimingAmount!

    private var stepLabel: UILabel!

    var rows: [RowItem] = [.claimableNow, .claimableFuture, .claimableTotal, .claimingAmount]
    private let tokenFormatter = TokenFormatter()

    convenience init(stepNumber: Int = 3,
                     maxSteps: Int = 4,
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
        tableView.registerCell(AllocationTotalCell.self)

        tableView.registerCell(AllocationBoxCell.self)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
        navigationItem.title = "Your Safe allocation"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
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
        case .claimableNow:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim now"
            cell.titleText = "Total"
            cell.valueText = "3,000.05 SAFE"
            cell.titleTooltipText = NSAttributedString(string: "This includes 1000 SAFE for user allocation and 2000.05 SAFE for guardian allocation.")
            cell.tooltipHostView = view
            // must be set at last
            cell.style = .darkGuardian
            return cell

        case .claimableFuture:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim in the future (vesting)"
            cell.titleText = "Total"
            cell.valueText = "6,000.10 SAFE"
            cell.headerTooltipText = NSAttributedString(string: "SAFE vesting is vested linearly over 4 years starting on 01.10.2022, 14:30:00 (Europe/Berlin).")
            cell.titleTooltipText = NSAttributedString(string: "This includes a Safe guardian allocation of 2000 SAFE.")
            cell.tooltipHostView = view
            cell.style = .lightGuardian
            return cell

        case .claimableTotal:
            let cell = tableView.dequeueCell(AllocationTotalCell.self)
            cell.text = "Awarded total allocation is 9000.15 SAFE"
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
