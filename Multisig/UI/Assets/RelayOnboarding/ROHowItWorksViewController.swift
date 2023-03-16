//
//  ROHowItWorksViewController.swift
//  Multisig
//
//  Created by Vitaly on 15.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ROHowItWorksViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var sec1TitleLabel: UILabel!
    @IBOutlet private weak var sec1Par1Label: UILabel!
    @IBOutlet private weak var moreComingSoonButton: UIButton!
    @IBOutlet private weak var sec2TitleLabel: UILabel!
    @IBOutlet private weak var sec2Par1Label: UILabel!
    @IBOutlet private weak var sec2Par2Label: UILabel!
    @IBOutlet private weak var sec3TitleLabel: UILabel!
    @IBOutlet private weak var sec3Par1Label: UILabel!
    @IBOutlet private weak var nextButton: UIButton!

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)

        sec1TitleLabel.setStyle(.headline)
        sec1Par1Label.setStyle(.subheadlineSecondary)

        sec2TitleLabel.setStyle(.headline)
        let sec2Par1String = "Our partner Gnosis Chain will temporarily sponsor your transactions via as the first test version. When the full version will be released, it will become a paid service. User can execute any type of transaction.".highlightRange(
            originalStyle: .subheadlineSecondary,
            highlightStyle: .subheadlineSecondary.color(.labelPrimary),
            textToHighlight: "Gnosis Chain")
        sec2Par1String.paragraph()
        sec2Par1Label.attributedText = sec2Par1String
        sec2Par2Label.setStyle(.subheadlineSecondary)

        sec3TitleLabel.setStyle(.headline)
        sec3Par1Label.setStyle(.subheadlineSecondary)

        nextButton.setText("Next", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayOnboarding3)
    }

    @IBAction func didTapNext(_ sender: Any) {
        completion()
    }
}
