//
//  AddSafeTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddSafeTableViewCell: UITableViewCell {
    @IBOutlet private weak var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        button.titleLabel?.setStyle(.button)
    }
    
}
