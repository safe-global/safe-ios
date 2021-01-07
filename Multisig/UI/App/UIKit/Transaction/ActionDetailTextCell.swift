//
//  ActionDetailTextCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailTextCell: ActionDetailTableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!

    func setText(_ text: String?, style: GNOTextStyle) {
        titleLabel.setStyle(style)
        titleLabel.text = text
    }

}
