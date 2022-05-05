//
//  ReviewChangeSafeTxViewController.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewAddOwnerTxViewController: ReviewSafeTransactionViewController {
    private var owner: KeyInfo!
    private var oldOwnersCount: Int = 0
    private var oldThreshold: Int = 0
    private var newThreshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 2
    var maxSteps: Int = 2
    var onSuccess: ((SCGModels.TransactionDetails) -> ())?
    convenience init(safe: Safe, owner: KeyInfo, oldOwnersCount: Int, oldThreshold: Int, newThreshold: Int) {
        self.init(safe: safe,
                  address: owner.address,
                  data: SafeTransactionController.shared.addOwnerWithThresholdData(owner: owner.address, threshold: newThreshold))
        self.owner = owner
        self.oldThreshold = oldThreshold
        self.oldOwnersCount = oldOwnersCount
        self.newThreshold = newThreshold
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        assert(safe != nil)

        tableView.registerCell(AddRemoveOwnerTableViewCell.self)
        confirmButtonView.title = "Submit"
        confirmButtonView.state = .normal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addAsOwnerReview)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {
        SafeTransactionController.shared.addOwnerWithThresholdTransaction(safe: safe,
                                                                          safeTxGas: safeTxGas,
                                                                          nonce: nonce,
                                                                          owner: owner.address,
                                                                          threshold: newThreshold)
    }

    override func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(AddRemoveOwnerTableViewCell.self)
        cell.set(owner: owner, action: .addingOwner)
        return cell
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required",
                 valueBefore: "\(oldThreshold) out of \(oldOwnersCount)",
                 valueAfter: "\(newThreshold) out of \(oldOwnersCount + 1)")
        cell.selectionStyle = .none

        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe owners", valueBefore: "\(oldOwnersCount)", valueAfter: "\(oldOwnersCount + 1)")
        cell.selectionStyle = .none
        return cell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        onSuccess?(transaction)
    }
}
