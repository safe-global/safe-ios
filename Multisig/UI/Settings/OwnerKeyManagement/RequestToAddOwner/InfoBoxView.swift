//
//  InfoBoxView.swift
//  Multisig
//
//  Created by Vitaly on 15.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoBoxView: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView.backgroundColor = .infoBackground
        backgroundView.layer.cornerRadius = 8
        messageLabel.setStyle(.callout)
    }

    func setText(_ text: String) {
        messageLabel.text = text
    }
}
