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

    func setText(_ text: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        button.setText(text, .plain)
    }

    @IBAction func didTapButton(_ sender: Any) {
        onTap()
    }
}
