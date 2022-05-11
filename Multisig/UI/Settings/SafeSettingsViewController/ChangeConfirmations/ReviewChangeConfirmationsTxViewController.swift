//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewChangeConfirmationsTxViewController: ReviewSafeTransactionViewController {
    private var ownersCount: Int = 0
    private var oldThreshold: Int = 0
    private var newThreshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 1
    var maxSteps: Int = 2

    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    var changeConfirmationsFlow: ChangeConfirmationsFlow!

    convenience init(safe: Safe, ownersCount: Int, oldThreshold: Int, newThreshold: Int) {
        //TODO How to get rid of the address? Or do we need it?
        self.init(
                safe: safe,
                address: try! Address(from: safe.address!),
                data: SafeTransactionController.shared.changeThresholdData(threshold: newThreshold)
        )

        self.ownersCount = ownersCount
        self.oldThreshold = oldThreshold
        self.newThreshold = newThreshold
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        confirmButtonView.title = "Submit"
        confirmButtonView.state = .normal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.reviewChangeConfirmations)
    }

    override func createSections() {
        sectionItems = [SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {
        SafeTransactionController.shared.changeThreshold(
                safe: safe,
                safeTxGas: safeTxGas,
                nonce: nonce,
                threshold: newThreshold
        )
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required", valueBefore: "\(oldThreshold) out of \(ownersCount)", valueAfter: "\(newThreshold) out of \(ownersCount)")
        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe owners", value: "\(ownersCount)")
        return cell
    }

    override func getTrackingEvent() -> TrackingEvent {
        .settingsTxAdvancedParams
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        onSuccess?(transaction)
    }
}
