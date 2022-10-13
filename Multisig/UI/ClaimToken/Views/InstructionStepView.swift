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
    @IBOutlet weak var horizontalStackView: UIStackView!
    @IBOutlet weak var bulletPointLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        descriptionLabel.setStyle(.callout)
        bulletPointLabel.text = "\u{2022}"
        bulletPointLabel.setStyle(.callout)
    }

    func setData(description: String) {
        descriptionLabel.text = description
    }
}
