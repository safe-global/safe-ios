//
//  TokenDistributionViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenDistributionViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet weak var distributionView: BorderedCheveronButton!

    private var onNext: (() -> ())?
    private var stepNumber: Int = 1
    private var maxSteps: Int = 4

    private var stepLabel: UILabel!

    convenience init(stepNumber: Int = 1, maxSteps: Int = 4, onNext: @escaping () -> ()) {
        self.init(namedClass: TokenDistributionViewController.self)
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        distributionView.set("Distribution details") {
            //TODO: Show distribution details
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
