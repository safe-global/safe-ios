//
//  BorderedCheveronButton.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BorderedCheveronButton: UINibView {
    private var onClick: (() -> ())?
    @IBOutlet private weak var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.setStyle(.primary)
        layer.borderWidth = 2
        layer.cornerRadius = 10
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.border.cgColor
    }

    @IBAction func actionButtonTouched(_ sender: Any) {
        onClick?()
    }

    func set(_ text: String, onClick: (() -> ())?) {
        textLabel.text = text
        self.onClick = onClick
    }
}
