//
//  LabeledTextField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LabeledTextField: UINibView {

    var text: String? {
        gnoTextField?.text
    }

    @IBOutlet weak var infoLabel: InfoLabel!
    @IBOutlet weak var gnoTextField: GNOTextField!
    @IBOutlet weak var captionLabel: UILabel!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    var validator: TextValidator!
    weak var fieldDelegate: FieldDelegate?

    override func commonInit() {
        super.commonInit()
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
        fieldDelegate?.textFieldFocused(textField)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString?
        let updatedText = text?.replacingCharacters(in: range, with: string)
        let validatedText = validator.validated(oldValue: textField.text, newPartialValue: updatedText)
        textField.text = validatedText

        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.fieldDelegate?.validate()
        })
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        fieldDelegate?.textFieldLostFocus(textField)
    }
}
