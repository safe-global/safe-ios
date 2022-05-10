//
// Created by Dirk Jäckel on 10.05.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewChangeConfirmationsTxViewController: ReviewSafeTransactionViewController {
    private var ownersCount: Int = 0
    private var threshold: Int = 0

    private var stepLabel: UILabel!

    var stepNumber: Int = 1
    var maxSteps: Int = 2

    var onSuccess: ((SCGModels.TransactionDetails) -> ())?

    var changeConfirmationsFlow: ChangeConfirmationsFlow!

    convenience init(safe: Safe, ownersCount: Int, oldThreshold: Int, newThreshold: Int) {
        //TODO How to get rid of the address? Or do we need it
        self.init(safe: safe, address: try! Address(from: safe.address!),  data: SafeTransactionController.shared.changeThreshold(threshold: 0)) //Add tx type swap owner

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

        tableView.registerCell(ReplaceOwnerTableViewCell.self) // TODO ?
        confirmButtonView.title = "Submit"
        confirmButtonView.state = .normal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.replaceOwnerReview) // TODO
    }

    override func createSections() {
        sectionItems = [//SectionItem.header(headerCell()), // TODO can this be removed?
                        SectionItem.safeInfo(safeInfoCell()),
                        SectionItem.valueChange(confirmationsCell()),
                        SectionItem.valueChange(ownersCell()),
                        SectionItem.advanced(parametersCell())]
    }

    override func createTransaction() -> Transaction? {
//        SafeTransactionController.shared.changeThreshold(
//                safe: safe,
//                prevOwner: previousOwner,
//                oldOwner: ownerToBeDeleted,
//                safeTxGas: safeTxGas,
//                nonce: nonce
//        )
    return nil
    }

//    override func headerCell() -> UITableViewCell {
//        // TODO no header cell in this case
//        let cell = tableView.dequeueCell(ReplaceOwnerTableViewCell.self)
////
////        let (newOwnerName, _) = NamingPolicy.name(for: owner.address,
////                info: nil,
////                chainId: safe.chain!.id!)
////
////        let (oldOwnerName, _) = NamingPolicy.name(for: ownerToBeReplaced,
////                info: nil,
////                chainId: safe.chain!.id!)
////
////        cell.set(
////                newOwner: AddressInfo(address: owner.address, name: newOwnerName),
////                oldOwner: AddressInfo(address: ownerToBeReplaced, name: oldOwnerName)
////        )
////
//        return cell
//    }

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
        //onSuccess?(transaction)
    }
}
