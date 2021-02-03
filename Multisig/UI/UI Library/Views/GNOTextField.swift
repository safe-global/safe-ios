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
        errorLabel.setStyle(.error)

        textField.borderStyle = .none
        textField.setStyle(.primary)
    }

    func setPlaceholder(_ text: String?) {
        guard let text = text else {
            textField.attributedPlaceholder = nil
            return
        }
        let attributes = GNOTextStyle.tertiary.attributes
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: attributes)
    }

    func setError(_ error: Error?) {
        errorLabel.text = error?.localizedDescription
        errorLabel.isHidden = error == nil
        borderView.tintColor = error == nil ? .gray4 : .error
    }
}
