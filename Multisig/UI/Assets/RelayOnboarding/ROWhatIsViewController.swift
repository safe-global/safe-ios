//
//  ROWhatIsViewController.swift
//  Multisig
//
//  Created by Vitaly on 09.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ROWhatIsViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var paragraph1Label: UILabel!
    @IBOutlet private weak var paragraph2TitleLabel: UILabel!
    @IBOutlet private weak var paragraph2Label: UILabel!
    @IBOutlet private weak var paragraph3TitleLabel: UILabel!
    @IBOutlet private weak var paragraph3Label: UILabel!
    @IBOutlet private weak var paragraph4Label: UILabel!
    @IBOutlet private weak var nextButton: UIButton!

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)
        paragraph1Label.setStyle(.subheadlineSecondary)
        paragraph2TitleLabel.setStyle(.headline)
        paragraph2Label.setStyle(.subheadlineSecondary)
        paragraph3TitleLabel.setStyle(.headline)
        paragraph3Label.setStyle(.subheadlineSecondary)
        paragraph4Label.setStyle(.subheadlineSecondary)

        nextButton.setText("Next", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Tracker.trackEvent()
    }

    @IBAction func didTapNext(_ sender: Any) {
        completion()
    }
}
