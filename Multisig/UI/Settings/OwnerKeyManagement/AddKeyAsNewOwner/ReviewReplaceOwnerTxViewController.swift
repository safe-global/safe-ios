//
// Created by Dirk Jäckel on 03.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewReplaceOwnerTxViewController: ReviewSafeTransactionViewController {
    private var owner: Address!
    private var newAddressName: String? = nil
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
        owner: Address,
        ownerToBeReplaced: Address,
        previousOwner: Address?,
        ownersCount: Int,
        threshold: Int,
        newAddressName: String? = nil
    ) {
        self.init(safe: safe)
        self.owner = owner
        self.ownerToBeReplaced = ownerToBeReplaced
        self.previousOwner = previousOwner
        self.ownersCount = ownersCount
        self.threshold = threshold
        self.newAddressName = newAddressName

        trackingEvent = .settingsTxAdvancedParams
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        tableView.registerCell(ReplaceOwnerTableViewCell.self)
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
            newOwner: owner,
            safeTxGas: safeTxGas,
            nonce: nonce
        )
    }

    override func headerCell() -> UITableViewCell {
            let cell = tableView.dequeueCell(ReplaceOwnerTableViewCell.self)

            let (newOwnerName, _) = NamingPolicy.name(for: owner,
                                                    info: nil,
                                                    chainId: safe.chain!.id!)

            let (oldOwnerName, _) = NamingPolicy.name(for: ownerToBeReplaced,
                                                info: nil,
                                                chainId: safe.chain!.id!)

            let newName = newAddressName ?? newOwnerName

            cell.set(
                newOwner: AddressInfo(address: owner, name: newName),
                oldOwner: AddressInfo(address: ownerToBeReplaced, name: oldOwnerName),
                prefix: safe.chain?.shortName
            )
        
            return cell
    }

    func confirmationsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Confirmations required", value: "\(threshold) out of \(ownersCount)")
        return cell
    }

    func ownersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ValueChangeTableViewCell.self)
        cell.set(title: "Safe Account owners", value: "\(ownersCount)")
        return cell
    }

    override func getTrackingEvent() -> TrackingEvent {
        .settingsTxAdvancedParams
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {
        onSuccess?(transaction)
    }
}
