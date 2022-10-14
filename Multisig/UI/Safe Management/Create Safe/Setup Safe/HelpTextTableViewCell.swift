//
//  HelpTextTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class HelpTextTableViewCell: UITableViewCell {
    @IBOutlet weak var cellLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellLabel.setStyle(.footnote)
    }

    func setText(_ text: String?) {
        cellLabel.text = text
    }

}
