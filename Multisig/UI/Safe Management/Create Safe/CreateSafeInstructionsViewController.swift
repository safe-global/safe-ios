//
//  CreateSafeInstructionsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateSafeInstructionsViewController: InstructionsViewController {

    convenience init() {
        self.init(namedClass: InstructionsViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "How does it work?"

        steps = [
            .header,
            .step(number: "1", title: "Choose a name", description: "How do you want to identify your Safe?"),
            .step(number: "2", title: "Select network", description: "Safe will only exist on the selected network."),
            .step(number: "3", title: "Add owners", description: "Owners are owner keys that control Safe. Add owners and specify the number of required signatures."),
            .step(number: "4", title: "Pay network fee", description: "A network fee is required for creation, as Gnosis Safe is a smart contract. Gnosis doesn’t profit from the fees."),
            .finalStep(title: "Start using your Safe!")
        ]

        button.setText("OK, Let’s start", .filled)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.createSafeIntro)
    }
}
