//
//  WhatIsSafeViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WhatIsSafeViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet weak var safeProtocolView: BorderedCheveronButton!
    @IBOutlet weak var interfacesView: BorderedCheveronButton!
    @IBOutlet weak var assetsView: BorderedCheveronButton!
    @IBOutlet weak var tokenomicsView: BorderedCheveronButton!
    
    private var onNext: (() -> ())?
    private var stepNumber: Int = 1
    private var maxSteps: Int = 3

    private var stepLabel: UILabel!

    convenience init(stepNumber: Int = 1, maxSteps: Int = 4, onNext: @escaping () -> ()) {
        self.init(namedClass: WhatIsSafeViewController.self)
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        safeProtocolView.set("Interfaces") {

        }

        interfacesView.set("Interfaces") {

        }

        assetsView.set("On-chain assets") {

        }

        tokenomicsView.set("Tokenomics") {

        }

        titleLabel.setStyle(.Updated.title)
        descriptionLabel.setStyle(.secondary)
        nextButton.setText("Next", .filled)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
    }

    @IBAction func didTapNext(_ sender: Any) {
        onNext?()
    }
}
