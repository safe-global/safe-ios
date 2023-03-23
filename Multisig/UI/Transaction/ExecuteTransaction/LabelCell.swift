//
//  LabelCell.swift
//  Multisig
//
//  Created by Vitaly on 23.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class LabelCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        label.setStyle(.headlinePrimary)
    }

    func setText(text: String) {
        label.text = text
    }
}
