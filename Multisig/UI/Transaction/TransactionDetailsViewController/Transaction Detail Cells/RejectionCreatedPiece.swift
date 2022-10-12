//
//  ConfirmationCreatedPiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class RejectionCreatedPiece: UINibView {

    @IBOutlet private weak var textLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headlineError)
    }

}
