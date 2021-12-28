//
//  ReviewSendFundsTransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewSendFundsTransactionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var estimationFailedLabel: UILabel!
    @IBOutlet weak var estimationFailedDescriptionLabel: UILabel!
    
    var toAddress: Address!
    var amount: String!
    var safe: Safe!
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(toAddress != nil)
        assert(amount != nil)
        assert(safe != nil)

        confirmButton.setText("Confirm", .filled)
        retryButton.setText("Retry", .filled)
        descriptionLabel.setStyle(.footnote2)
    }

    @IBAction func confirmButtonTouched(_ sender: Any) {

    }

    @IBAction func retryButtonTouched(_ sender: Any) {

    }
}
