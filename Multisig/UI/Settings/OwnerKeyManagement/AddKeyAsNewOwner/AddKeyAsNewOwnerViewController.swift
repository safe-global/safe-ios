//
//  AddKeyAsNewOwnerViewController.swift
//  Multisig
//
//  Created by Vitaly on 25.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddKeyAsNewOwnerViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.primary)
        descriptionLabel.setStyle(.secondary)
        addButton.setText("Add as owner", .filled)
        skipButton.setText("Skip", .plain)
    }

    @IBAction func didTapAddButton(_ sender: Any) {
    }

    @IBAction func didTapSkipButton(_ sender: Any) {
    }
}
