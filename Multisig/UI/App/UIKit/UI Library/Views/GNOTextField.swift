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
        errorLabel.setStyle(GNOTextStyle.callout.color(.gnoTomato))

        textField.borderStyle = .none
        textField.font = UIFont.gnoFont(forTextStyle: .body)
        textField.textColor = GNOTextStyle.body.color
    }

    func setPlaceholder(_ text: String?) {
        guard let text = text else {
            textField.attributedPlaceholder = nil
            return
        }
        let attributes = GNOTextStyle.body.color(.gnoMediumGrey).attributes
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: attributes)
    }

    func setError(_ error: Error?) {
        errorLabel.text = error?.localizedDescription
        errorLabel.isHidden = error == nil
        borderView.tintColor = error == nil ? .gnoWhitesmoke : .gnoTomato
    }
}
