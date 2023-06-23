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
        navigationItem.largeTitleDisplayMode = .never
        title = "How does it work?"

        steps = [
            .header,
            .step(number: "1", title: "Choose a name", description: "How do you want to identify your Safe Account?"),
            .step(number: "2", title: "Add owners", description: "Owners are owner keys that control Safe Account. Add owners and specify the number of required signatures."),
            .step(number: "3", title: "Pay network fee", description: "A network fee is required for creation, as Safe Account is a smart contract. We don’t profit from the fees."),
            .finalStep(title: "Start using your Safe Account!")
        ]

        button.setText("OK, Let’s start", .filled)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.createSafeIntro)
    }
}
