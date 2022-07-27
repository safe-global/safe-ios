//
//  ClaimNotAvailableViewController.swift
//  Multisig
//
//  Created by Vitaly on 26.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimNotAvailableViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var safeDAOLink: HyperlinkButtonView!
    @IBOutlet weak var forumLink: HyperlinkButtonView!
    @IBOutlet weak var okButton: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        titleLabel.setStyle(.claimTitle)

        descriptionLabel.setStyle(.secondary)

        safeDAOLink.setText("Safe DAO")
        safeDAOLink.url = App.configuration.contact.safeDAOURL

        forumLink.setText("Forum")
        forumLink.url = App.configuration.contact.forumURL

        okButton.setText("OK, I Understand", .filled)
    }

    @IBAction func didTapOkButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
