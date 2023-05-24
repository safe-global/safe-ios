//
//  ReviewRemoveOwnerViewController.swift
//  Multisig
//
//  Created by Moaaz on 5/10/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewRemoveOwnerViewController: ReviewSafeTransactionViewController {
    private var owner: Address!
    private var previousOwner: Address?
    private var oldOwnersCount: Int = 0
    private var oldThreshold: Int = 0
    private var newThreshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 2
    var maxSteps: Int = 2

    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    convenience init(safe: Safe, owner: Address, previousOwner: Address?, oldOwnersCount: Int, oldThreshold: Int, newThreshold: Int) {
        self.init(safe: safe)
        self.owner = owner
        self.oldThreshold = oldThreshold
        self.oldOwnersCount = oldOwnersCount
        self.newThreshold = newThreshold
        self.previousOwner = previousOwner
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        assert(safe != nil)

        tableView.registerCell(AddRemoveOwnerTableViewCell.self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.removeOwnerReview)
    }

    override func createSections() {
        sectionItems = [SectionItem.header(headerCell()),
                        SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {
        SafeTransactionController.shared.removeOwner(safe: safe,
                                                     safeTxGas: safeTxGas,
                                                     prevOwner: previousOwner,
                                                     oldOwner: owner,
                                                     nonce: nonce,
                                                     threshold: newThreshold)
    }

    override func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(AddRemoveOwnerTableViewCell.self)

        let (name, _) = NamingPolicy.name(for: owner,
                                                    info: nil,
                                                    chainId: safe.chain!.id!)

        cell.set(owner: AddressInfo(address: owner, name: name), action: .removingOwner, prefix: safe.chain?.shortName)

        return cell
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required",
                 valueBefore: "\(oldThreshold) out of \(oldOwnersCount)",
                 valueAfter: "\(newThreshold) out of \(oldOwnersCount - 1)")
        cell.selectionStyle = .none

        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe Account owners", valueBefore: "\(oldOwnersCount)", valueAfter: "\(oldOwnersCount - 1)")
        cell.selectionStyle = .none
        return cell
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        onSuccess?(transaction)
    }

    override func getTrackingEvent() -> TrackingEvent {
        .settingsTxAdvancedParams
    }
}
