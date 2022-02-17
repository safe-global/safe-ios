//
//  ChooseOwnerDetailHeaderView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseOwnerDetailHeaderView: UINibView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var detailTextLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.primary)
        textLabel.text = nil
        detailTextLabel.setStyle(.tertiary)
        detailTextLabel.text = nil
    }

}
