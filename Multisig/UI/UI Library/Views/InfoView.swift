//
//  InfoView.swift
//  Multisig
//
//  Created by Mouaz on 6/20/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoView: UINibView {
    @IBOutlet private weak var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 8
        textLabel.setStyle(.subheadline1Medium)
    }

    func set(text: String) {
        textLabel.text = text
        layoutIfNeeded()
    }
}
