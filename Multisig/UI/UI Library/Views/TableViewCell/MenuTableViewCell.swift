//
//  MenuTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var disclosureImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    let buttonStyle: GNOButtonStyle = .plain

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        button.setText("", buttonStyle)
        button.showsMenuAsPrimaryAction = true
    }

    var menu: UIMenu? {
        get { button.menu }
        set { button.menu = newValue }
    }

    var text: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var detailText: String? {
        get { button.title(for: .normal) }
        set { button.setText(newValue, buttonStyle)}
    }
}
