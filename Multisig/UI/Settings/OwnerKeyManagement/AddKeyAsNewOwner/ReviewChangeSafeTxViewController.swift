//
//  ReviewChangeSafeTxViewController.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewChangeSafeTxViewController: ReviewSafeTransactionViewController {

    convenience init(safe: Safe,
                     owner: KeyInfo) {
        self.init(safe: safe, address: owner.address)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(safe != nil)

        tableView.registerCell(AddRemoveOwnerTableViewCell.self)

        sectionItems = [SectionItem.basic(headerCell()), SectionItem.advanced(ownerActionCell()())]
        tableView.reloadData()
    }

    private func ownerActionCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(AddRemoveOwnerTableViewCell.self)

        let keyInfo = KeyInfo.all()[0]
        cell.set(owner: keyInfo, action: .addingOwner)

        return cell
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //TODO: track screen
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {

    }
}
