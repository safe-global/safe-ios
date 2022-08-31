//
//  InstructionStepView.swift
//  Multisig
//
//  Created by Vitaly on 21.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InstructionStepView: UINibView {

    @IBOutlet weak var descriptionLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        descriptionLabel.setStyle(.secondary)
    }

    func setData(description: String) {
        descriptionLabel.text = description
    }
}
