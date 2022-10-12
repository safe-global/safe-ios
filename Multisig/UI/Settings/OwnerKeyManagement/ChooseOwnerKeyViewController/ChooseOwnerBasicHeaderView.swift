//
//  ChooseOwnerBasicHeaderView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseOwnerBasicHeaderView: UINibView {
    @IBOutlet weak var textLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headline)
        textLabel.text = ""
    }

}
