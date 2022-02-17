//
//  ButtonTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {
    var onTap: () -> Void = {}

    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var buttonHeight: NSLayoutConstraint!

    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var trailing: NSLayoutConstraint!
    @IBOutlet weak var leading: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!

    var height: CGFloat {
        get { buttonHeight.constant }
        set {
            buttonHeight.constant = newValue
            setNeedsLayout()
        }
    }

    var padding: CGFloat = 0 {
        didSet {
            top.constant = padding
            bottom.constant = padding
            trailing.constant = padding
            leading.constant = padding
            setNeedsLayout()
        }
    }

    func setText(_ text: String, style: GNOButtonStyle = .primary, onTap: @escaping () -> Void) {
        self.onTap = onTap
        button.setText(text, style)
    }

    @IBAction func didTapButton(_ sender: Any) {
        onTap()
    }
}
