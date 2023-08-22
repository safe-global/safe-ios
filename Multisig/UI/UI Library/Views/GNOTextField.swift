//
//  GNOTextField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class GNOTextField: UINibView {
    @IBOutlet private(set) weak var textField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var borderView: UIImageView!

    override func commonInit() {
        super.commonInit()
        setError(nil)
        errorLabel.setStyle(.calloutError)

        textField.borderStyle = .none
        textField.setStyle(.bodyPrimary)
    }

    func setPlaceholder(_ text: String?) {
        guard let text = text else {
            textField.attributedPlaceholder = nil
            return
        }
        let attributes = GNOTextStyle.bodyTertiary.attributes
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: attributes)
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var errorText: String? {
        errorLabel.text
    }

    func setError(_ error: Error?) {
        setErrorText(error?.localizedDescription)
    }

    func setErrorText(_ value: String?) {
        errorLabel.text = value
        errorLabel.isHidden = value == nil
        borderView.tintColor = value == nil ? .border : .error
    }
}
