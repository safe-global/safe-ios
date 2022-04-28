//
//  ReviewChangeSafeTxViewController.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewChangeSafeTxViewController: ReviewSafeTransactionViewController {

    private var owner: KeyInfo!

    convenience init(safe: Safe, owner: KeyInfo) {
        self.init(safe: safe, address: owner.address)
        self.owner = owner
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(safe != nil)

        tableView.registerCell(AddRemoveOwnerTableViewCell.self)

        nonce = "0"
        safeTxGas = "0"
        minimalNonce = "0"
        bindData()
    }

    override func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(AddRemoveOwnerTableViewCell.self)
        cell.set(owner: owner, action: .addingOwner)
        return cell
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //TODO: track screen
    }

    override func onSuccess(transaction: SCGModels.TransactionDetails) {

    }
}
