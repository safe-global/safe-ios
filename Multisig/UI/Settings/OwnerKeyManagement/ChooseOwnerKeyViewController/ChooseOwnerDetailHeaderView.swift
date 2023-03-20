//
//  ChooseOwnerDetailHeaderView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseOwnerDetailHeaderView: UINibView {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var detailTextLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.body)
        textLabel.text = nil
        detailTextLabel.setStyle(.body)
        detailTextLabel.text = nil
    }

}
