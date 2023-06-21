//
//  CreateSafeWithSocialIntroViewController.swift
//  Multisig
//
//  Created by Mouaz on 6/19/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateSafeWithSocialIntroViewController: UIViewController {
    @IBOutlet private weak var ribbonView: RibbonView!
    @IBOutlet private weak var googleButton: UIButton!
    @IBOutlet private weak var appleButton: UIButton!
    @IBOutlet private weak var addressButton: UIButton!
    @IBOutlet private weak var orLabel: UILabel!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var infoView3: InfoView!
    @IBOutlet private weak var infoView2: InfoView!
    @IBOutlet private weak var infoView1: InfoView!

    var chain: SCGModels.Chain!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create a Safe Account"
        ribbonView.update(scgChain: chain)
        orLabel.setStyle(.caption1)
        appleButton.setText("Continue with Apple ID", .filled)
        googleButton.setText("Continue with Google", .filled)
        addressButton.setText("Continue with a wallet address", .bordered)
        infoView1.set(text: "Create a Safe Account now and add more owners later for better security")
        infoView2.set(text: "Owner key is protected by your social login")
        infoView3.set(text: "No need to keep seed phrases")
        headerLabel.hyperLinkLabel("Select a social login to create your Safe Account. ",
                                   prefixStyle: .body,
                                   linkText: "How does it work?",
                                   linkStyle: .button,
                                   linkIcon: nil,
                                   underlined: false)
    }


    @IBAction private func addressButtonTouched(_ sender: Any) {
        let instructionsVC = CreateSafeInstructionsViewController()
        instructionsVC.chain = chain
        show(instructionsVC, sender: self)
    }
}
