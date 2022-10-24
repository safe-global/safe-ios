//
//  ConfirmationCreatedPiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmationCreatedPiece: UINibView {

    @IBOutlet private weak var textLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headlinePrimary)
        // I wish the XIB would allow to set the height constraint to
        // the file owner, but it doesn't, so we set it in code here
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50)
        ])
    }

}
