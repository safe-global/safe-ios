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
    var stepNumber: Int = 1
    var maxSteps: Int = 3

    private var stepLabel: UILabel!

    var onChooseGuardian: (() -> ())?
    var onCustomAddress: (() -> ())?
    convenience init(stepNumber: Int = 1, maxSteps: Int = 3, onChooseGuardian: @escaping () -> (), onCustomAddress: @escaping () -> ()) {
        self.init(namedClass: CreateInviteOwnerIntroViewController.self)
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onChooseGuardian = onChooseGuardian
        self.onCustomAddress = onCustomAddress
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.setStyle(.title5)
        descriptionLabel.setStyle(.secondary)
        chooseGuardianButton.setText("Delegate to a Safe Guardian", .filled)
        customAddressButton.setText("Custom address", .primary)
        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
    }

    @IBAction func didChooseGuardianButton(_ sender: Any) {
        onChooseGuardian?()
    }

    @IBAction func didCustomAddressButton(_ sender: Any) {
        onCustomAddress?()
    }
}
