//
//  InstructionStepListView.swift
//  Multisig
//
//  Created by Vitaly on 21.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InstructionStepListView: UIStackView {

    struct Step {
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
    }

    func setContent(steps: [Step]) {

        arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, step) in steps.enumerated() {
            let instructionView = InstructionStepView()
            instructionView.setData(step: index + 1, title: step.title, description: step.description, finalStep: index == steps.count - 1)
            addArrangedSubview(instructionView)
        }
    }
}
