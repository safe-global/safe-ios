//
// Created by Dirk Jäckel on 03.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewReplaceOwnerTxViewController: ReviewSafeTransactionViewController {
    private var owner: KeyInfo!
    private var ownerToBeReplaced: Address!
    private var previousOwner: Address?
    private var ownersCount: Int = 0
    private var threshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 2
    var maxSteps: Int = 2

    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    convenience init(
        safe: Safe,
        owner: KeyInfo,
        ownerToBeReplaced: Address,
        previousOwner: Address?,
        ownersCount: Int,
        threshold: Int) {
        self.init(safe: safe,
                address: owner.address,
                data: SafeTransactionController.shared.addOwnerWithThresholdData(owner: owner.address, threshold: 0)) //Add tx type swap owner
        self.owner = owner
        self.ownerToBeReplaced = ownerToBeReplaced
        self.previousOwner = previousOwner
        self.ownersCount = ownersCount
        self.threshold = threshold
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        tableView.registerCell(ReplaceOwnerTableViewCell.self)
        confirmButtonView.title = "Submit"
        confirmButtonView.state = .normal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.replaceOwnerReview)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {
        SafeTransactionController.shared.replaceOwner(
            safe: safe,
            prevOwner: previousOwner,
            oldOwner: ownerToBeReplaced,
            newOwner: owner.address,
            safeTxGas: safeTxGas,
            nonce: nonce
        )
    }

    override func headerCell() -> UITableViewCell {
            let cell = tableView.dequeueCell(ReplaceOwnerTableViewCell.self)
            cell.set(newOwner: owner, oldOwner: ownerToBeReplaced!)
            return cell
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required", value: "\(threshold) out of \(ownersCount)")
        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe owners", value: "\(ownersCount)")
        return cell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        onSuccess?(transaction)
    }
}
