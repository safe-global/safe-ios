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


    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        screenTitle.setStyle(.claimTitle)

        screenTitle.text = "What is the safe?"

        firstParagraph.setStyle(.secondary)
        firstParagraph.text = "Safe is critical infrastructure for web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.\nWith this token launch, Safe is now a community-driven ownership platform."

        paragraphTitle.setStyle(.secondary)
        paragraphTitle.text = "Why are we launching a token?"

        secondParagraph.setStyle(.secondary)
        secondParagraph.text = "As critical web3 infrastructure, Safe needs to be a community-owned, censorship resistant project, with a committed ecosystem stewarding its decisions. A governance token is needed to help coordinate this effort."
    }
}
