//
// Created by Dirk Jäckel on 03.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewReplaceOwnerTxViewController: ReviewSafeTransactionViewController {
    private var owner: KeyInfo!
    private var ownerToBeReplaced: KeyInfo!
    private var oldOwnersCount: Int = 0
    private var oldThreshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 2
    var maxSteps: Int = 2

    convenience init(safe: Safe, owner: KeyInfo, oldOwnersCount: Int, oldThreshold: Int, ownerToBeReplaced: KeyInfo) {
        self.init(safe: safe,
                address: owner.address,
                data: SafeTransactionController.shared.addOwnerWithThresholdData(owner: owner.address, threshold: 0)) //Add tx type swap owner
        self.owner = owner
        self.oldThreshold = oldThreshold
        self.oldOwnersCount = oldOwnersCount
//        self.newThreshold = newThreshold
        self.ownerToBeReplaced = ownerToBeReplaced
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        assert(safe != nil)

        tableView.registerCell(ReplaceOwnerTableViewCell.self)
        confirmButtonView.title = "Submit"
        confirmButtonView.state = .normal
    }



    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: Needs tracking events from separate PR
        //Tracker.trackEvent(.replaceOwnerReview)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {


        //TODO create swap owner tx

        SafeTransactionController.shared.addOwnerWithThresholdTransaction(safe: safe,
                safeTxGas: safeTxGas,
                nonce: nonce,
                owner: owner.address,
                threshold: oldThreshold)

    }

    override func headerCell() -> UITableViewCell {
            let cell = tableView.dequeueCell(ReplaceOwnerTableViewCell.self)
            cell.set(newOwner: owner, oldOwner: ownerToBeReplaced!)
            return cell
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required", valueAfter: "\(oldThreshold) out of \(oldOwnersCount)")
        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe owners", valueAfter: "\(oldOwnersCount)")

        return cell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {

    }

}
