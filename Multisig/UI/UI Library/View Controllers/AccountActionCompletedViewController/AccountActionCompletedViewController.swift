//
//  AccountActionCompletedViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/19/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AccountActionCompletedViewController: UIViewController {
    @IBOutlet weak var accountInfoView: AccountInfoView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!

    var titleText: String!
    var headerText: String!
    var descriptionText: String!
    var primaryActionName: String!
    var secondaryActionName: String!

    var accountName: String?
    var accountAddress: Address!
    var prefix: String?

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(titleText != nil)
        assert(headerText != nil)
        assert(descriptionText != nil)
        assert(primaryActionName != nil)
        assert(secondaryActionName != nil)
        assert(accountAddress != nil)

        navigationItem.hidesBackButton = true
        navigationItem.title = titleText

        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(.body)

        primaryButton.setText(primaryActionName, .filled)

        secondaryButton.setText(secondaryActionName, .primary)

        descriptionLabel.text = descriptionText
        headerLabel.text = headerText
        accountInfoView.set(accountName)
        accountInfoView.setAddress(accountAddress, prefix: prefix)
    }

    @IBAction func primaryAction(_ sender: Any) {
        // to override
    }

    @IBAction func secondaryAction(_ sender: Any) {
        // to override
    }
}
