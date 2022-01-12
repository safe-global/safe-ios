//
//  LabeledTextField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LabeledTextField: UINibView {

    @IBOutlet weak var infoLabel: InfoLabel!
    @IBOutlet weak var gnoTextField: GNOTextField!
    @IBOutlet weak var captionLabel: UILabel!

    static let textFieldHeight: CGFloat = 40

    private var textFieldHeightConstraint: NSLayoutConstraint!

    var onTextFieldDidBeginEditing: (LabeledTextField, UITextField) -> Void = { _, _  in }

    override func commonInit() {
        super.commonInit()
        textFieldHeightConstraint = gnoTextField.textField.heightAnchor.constraint(equalToConstant: Self.textFieldHeight)
        textFieldHeightConstraint.isActive = true
        setCaption(nil)
        gnoTextField.textField.delegate = self
    }

    func setCaption(_ value: String?, style: GNOTextStyle = .caption1.weight(.medium)) {
        captionLabel.text = value
        captionLabel.setStyle(style)
        captionLabel.isHidden = value == nil
    }
}

extension LabeledTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        onTextFieldDidBeginEditing(self, textField)
    }
}
