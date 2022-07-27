//
//  InstructionStepView.swift
//  Multisig
//
//  Created by Vitaly on 21.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InstructionStepView: UINibView {

    @IBOutlet weak var circleLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var verticalBarView: UIImageView!


    override func commonInit() {
        super.commonInit()
        circleLabel.setStyle(.secondary)
        headerLabel.setStyle(.title5)
        descriptionLabel.setStyle(.secondary)
    }

    func setData(step: Int, title: String, description: String, finalStep: Bool = false) {
        circleLabel.text = String(step)
        headerLabel.text = title
        descriptionLabel.text = description
        if finalStep {
            verticalBarView.isHidden = true
        } else {
            verticalBarView.isHidden = false
        }
    }
}
