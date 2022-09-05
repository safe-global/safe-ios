//
//  WhatIsSafeViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 02.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WhatIsSafeViewController: UIViewController {

    @IBOutlet weak var firstParagraph: UILabel!
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var highlight1: UILabel!
    @IBOutlet weak var highlight2: UILabel!
    @IBOutlet weak var paragraphTitle: UILabel!
    @IBOutlet weak var secondParagraph: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    var factory: ClaimSafeTokenFlowFactory!

    private var completion: (() -> Void)?

    convenience init(completion: @escaping () -> ()) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.makeTransparentNavigationBar(self)
        ViewControllerFactory.addCloseButton(self)

        screenTitle.text = "What is Safe?"
        screenTitle.setStyle(.claimTitle)

        firstParagraph.setStyle(.secondary)
        firstParagraph.text = "Safe is critical infrastructure for web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.\nWith this token launch, Safe is now a community-driven ownership platform."

        paragraphTitle.text = "Why are we launching a token?"
        paragraphTitle.setStyle(.title5)

        secondParagraph.setStyle(.secondary)
        secondParagraph.text = "As critical web3 infrastructure, Safe needs to be a community-owned, censorship resistant project, with a committed ecosystem stewarding its decisions. A governance token is needed to help coordinate this effort."

        nextButton.setText("Next", .filled)

    }

    @IBAction func nextClicked(_ sender: Any) {
        print("Next button clicked")
    }

}
