//
//  BenefitsListView.swift
//  Multisig
//
//  Created by Vitaly on 14.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class BenefitsListView: UIStackView {

    struct Benefit {
        let title: String
        let description: String
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        axis = .vertical

        alignment = .top
        distribution = .fill
        spacing = 24
    }

    func setContent(benefits: [Benefit]) {

        arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (_, benefit) in benefits.enumerated() {
            let benefitView = BenefitView()
            benefitView.setData(title: benefit.title, description: benefit.description)
            addArrangedSubview(benefitView)
        }
    }
}
