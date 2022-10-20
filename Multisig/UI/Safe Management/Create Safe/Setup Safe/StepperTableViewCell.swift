//
//  StepperTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class StepperTableViewCell: UITableViewCell {

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!

    var onChange: (Int) -> Void = { _ in }

    func setText(_ text: String?, style: GNOTextStyle = .body) {
        cellLabel.text = text
        cellLabel.setStyle(style)
    }

    func setRange(min: Int, max: Int, step: Int = 1) {
        stepper.minimumValue = Double(min)
        stepper.maximumValue = Double(max)
        stepper.stepValue = Double(step)
    }

    func setValue(_ value: Int) {
        stepper.value = Double(value)
    }

    @IBAction func didChangeStepperValue(_ sender: Any) {
        onChange(Int(stepper.value))
    }
}
