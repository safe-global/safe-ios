//
//  ClaimGetStartedViewController.swift
//  Multisig
//
//  Created by Vitaly on 21.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimGetStartedViewController: UIViewController {

    @IBOutlet private weak var startClaimButton: UIButton!
    @IBOutlet private weak var instructionsView: InstructionStepListView!
    @IBOutlet private weak var screenTitle: UILabel!

    private var instructionsVC: InstructionsViewController!

    var onStartClaim: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimWelcome)
        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never

        startClaimButton.setText("Start your claiming process", .filled)
        screenTitle.text = "Welcome to the next generation of digital ownership!"
        screenTitle.setStyle(.title1)

        instructionsView.setContent(steps: [
            InstructionStepListView.Step(
                description: "SafeDAO is on a mission to unlock digital ownership for everyone in Web3."
            ),
            InstructionStepListView.Step(
                description: "We will do this by establishing a universal standard for custody of digital assets, data and identity with smart contract based accounts."
            ),
            InstructionStepListView.Step(
                description: "You have been chosen to help govern the SafeDAO, and decide on the future of Web3 ownership. Use this power wisely!"
            )
        ])
    }

    @IBAction func didTapStartClaimButton(_ sender: Any) {
        Tracker.trackEvent(.userClaimStart)
        onStartClaim?()
    }
}
