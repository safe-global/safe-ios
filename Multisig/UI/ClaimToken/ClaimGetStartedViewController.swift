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

    private var stepLabel: UILabel!
    private var instructionsVC: InstructionsViewController!

    var onStartClaim: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        startClaimButton.setText("Start your claiming process", .filled)

        instructionsView.setContent(steps: [
            InstructionStepListView.Step(
                title: "The Safe DAO tokenomics",
                description: "How do you want to identify your Safe?"
            ),
            InstructionStepListView.Step(
                title: "Our governance model",
                description: "Safe will only exist on the selected network."
            ),
            InstructionStepListView.Step(
                title: "How to earn with SAFE tokens",
                description: "Owners are owner keys that control Safe. Add owners and specify the number of required signatures."
            )
        ])


        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @IBAction func didTapStartClaimButton(_ sender: Any) {
        onStartClaim?()
    }
}
