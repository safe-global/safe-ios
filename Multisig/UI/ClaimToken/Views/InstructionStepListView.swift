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

        for (_, step) in steps.enumerated() {
            let instructionView = InstructionStepView()
            instructionView.setData(description: step.description)
            addArrangedSubview(instructionView)
        }
    }
}
