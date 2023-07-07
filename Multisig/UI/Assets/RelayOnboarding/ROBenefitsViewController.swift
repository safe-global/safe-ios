//
//  ROBenefitsViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ROBenefitsViewController: UIViewController {

    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var benefitsListView: BenefitsListView!
    
    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)

        benefitsListView.setContent(benefits: [
            BenefitsListView.Benefit(
                title: "Free 5 transactions per hour",
                description: "We pay for your Safe Account transactions for up to five transactions per hour on Gnosis chain."
            ),
            BenefitsListView.Benefit(
                title: "Scalability for signer accounts",
                description: "Use your owner keys as \"throw-away accounts\" or \"signing-only accounts\" to make execution more smooth."
            ),
            BenefitsListView.Benefit(
                title: "No need to distribute tokens",
                description: "Your ETH or other native assets are always at your disposal for the payment."
            ),
            BenefitsListView.Benefit(
                title: "Full flexibility",
                description: "Choose to execute with your connected wallet/owner keys or with a relayer any time."
            )
        ])
        
        nextButton.setText("Next", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayOnboarding2)
    }

    @IBAction func didTapNext(_ sender: Any) {
        completion()
    }
}
