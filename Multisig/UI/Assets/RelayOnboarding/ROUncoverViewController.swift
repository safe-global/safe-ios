//
//  ROUncoverViewController.swift
//  Multisig
//
//  Created by Vitaly on 15.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ROUncoverViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var par1Label: UILabel!
    @IBOutlet private weak var par2Label: UILabel!
    @IBOutlet private weak var par3Label: UILabel!
    @IBOutlet private weak var doneButton: UIButton!

    var completion: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title1)

        par1Label.setStyle(.subheadlineSecondary)
        par2Label.setStyle(.subheadlineSecondary)
        par3Label.setStyle(.subheadlineSecondary)

        doneButton.setText("Done", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayOnboarding4)
    }

    @IBAction func didTapDone(_ sender: Any) {
        completion()
    }
}
