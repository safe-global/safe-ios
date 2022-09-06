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
    @IBOutlet weak var totalSafesCreatedLabel: UILabel!
    @IBOutlet weak var totalValueProtected: UILabel!
    @IBOutlet weak var paragraphTitle: UILabel!
    @IBOutlet weak var secondParagraph: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    @IBOutlet weak var totalValueProtectedStackView: UIStackView!
    @IBOutlet weak var totalSafesCreatedStackView: UIStackView!

    private var stepLabel: UILabel!

    private var onNext: (() -> ())?
    private var stepNumber: Int = 1
    private var maxSteps: Int = 4

    var factory: ClaimSafeTokenFlowFactory!

    private var completion: (() -> Void)?

    convenience init(stepNumber: Int = 1, maxSteps: Int = 4, onNext: @escaping () -> ()) {
        self.init(namedClass: WhatIsSafeViewController.self)
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.completion = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO How to get the back button and not line beween navbar and content?
//        ViewControllerFactory.makeTransparentNavigationBar(self)

        screenTitle.text = "What is Safe?"
        screenTitle.setStyle(.claimTitle)

        firstParagraph.setStyle(.secondary)
        firstParagraph.text = "Safe is critical infrastructure for web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.\nWith this token launch, Safe is now a community-driven ownership platform."

        paragraphTitle.text = "Why are we launching a token?"
        paragraphTitle.setStyle(.title5)

        secondParagraph.setStyle(.secondary)
        secondParagraph.text = "As critical web3 infrastructure, Safe needs to be a community-owned, censorship resistant project, with a committed ecosystem stewarding its decisions. A governance token is needed to help coordinate this effort."

        nextButton.setText("Next", .filled)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"


        totalSafesCreatedLabel.setStyle(.callout)
        totalValueProtected.setStyle(.callout)

        totalValueProtectedStackView.layer.cornerRadius = 10
        totalSafesCreatedStackView.layer.cornerRadius = 10
    }

    @IBAction func nextClicked(_ sender: Any) {
        print("Next button clicked")
    }

}
