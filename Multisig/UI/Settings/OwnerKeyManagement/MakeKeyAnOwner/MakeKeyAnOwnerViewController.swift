//
//  MakeKeyAnOwnerViewController.swift
//  Multisig
//
//  Created by Vitaly on 13.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class MakeKeyAnOwnerViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addOwnerView: AddOwnerView!
    @IBOutlet weak var infoBoxView: InfoBoxView!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    var safe: Safe!
  
    var onContinue: (() -> ())!
    var onReject: (() -> ())!

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        titleLabel.setStyle(.primary)
        messageLabel.setStyle(.secondary)
        infoBoxView.setText("Make sure you trust this key before confirming.")
        rejectButton.setText("Reject", .filledError)
        continueButton.setText("Continue...", .filled)
     }

    @IBAction func didTapReject(_ sender: Any) {
        onReject()
    }

    @IBAction func didTapContinue(_ sender: Any) {
        onContinue()
    }
}
