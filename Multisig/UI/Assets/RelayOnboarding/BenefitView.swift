//
//  BenefitView.swift
//  Multisig
//
//  Created by Vitaly on 14.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class BenefitView: UINibView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headlinePrimary)
        descriptionLabel.setStyle(.subheadlineSecondary)
    }

    func setData(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
