//
//  ChooseDelegateIntroViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseDelegateIntroViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var chooseGuardianButton: UIButton!
    @IBOutlet weak var customAddressButton: UIButton!

    var onChooseGuardian: (() -> ())?
    var onCustomAddress: (() -> ())?
    convenience init(onChooseGuardian: @escaping () -> (), onCustomAddress: @escaping () -> ()) {
        self.init(namedClass: ChooseDelegateIntroViewController.self)
        self.onChooseGuardian = onChooseGuardian
        self.onCustomAddress = onCustomAddress
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimChdel)

        ViewControllerFactory.removeNavigationBarBorder(self)

        titleLabel.setStyle(.title2)

        descriptionLabel.setStyle(.body)
        descriptionLabel.textAlignment = .left

        chooseGuardianButton.setText("Delegate to a Safe Guardian", .filled)
        customAddressButton.setText("Delegate to custom address or ENS", .primary)
    }

    @IBAction func didChooseGuardianButton(_ sender: Any) {
        Tracker.trackEvent(.userClaimChdelGuard)
        onChooseGuardian?()
    }

    @IBAction func didCustomAddressButton(_ sender: Any) {
        Tracker.trackEvent(.userClaimChdelAddr)
        onCustomAddress?()
    }
}
