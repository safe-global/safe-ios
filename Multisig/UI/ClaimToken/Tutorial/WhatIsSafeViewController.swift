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

    private var onNext: (() -> ())?

    convenience init(onNext: @escaping () -> ()) {
        self.init(namedClass: WhatIsSafeViewController.self)
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimWhatis)

        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never

        screenTitle.text = "What is Safe?"
        screenTitle.setStyle(.title2)

        firstParagraph.setStyle(.body)
        firstParagraph.text = "Safe is critical infrastructure for Web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.\n\nWith this token launch, Safe is now a community-driven ownership platform."

        paragraphTitle.text = "Why are we launching a token?"
        paragraphTitle.setStyle(.headline)

        secondParagraph.setStyle(.body)
        secondParagraph.text = "As critical Web3 infrastructure, Safe needs to be a community-owned, censorship resistant project, with a committed ecosystem stewarding its decisions. A governance token is needed to help coordinate this effort."

        nextButton.setText("Next", .filled)

        totalSafesCreatedLabel.setStyle(.callout)
        totalSafesCreatedStackView.layer.cornerRadius = 10

        totalValueProtected.setStyle(.callout)
        totalValueProtectedStackView.layer.cornerRadius = 10
    }

    @IBAction func nextClicked(_ sender: Any) {
        Tracker.trackEvent(.userClaimWhatisNext)
        onNext?()
    }
}
