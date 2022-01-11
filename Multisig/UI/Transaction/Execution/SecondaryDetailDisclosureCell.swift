//
//  SecondaryDetailDisclosureCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SecondaryDetailDisclosureCell: UITableViewCell {

    @IBOutlet weak var cellLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellLabel.setStyle(.primary)
        self.backgroundView = UIView()
        setBackgroundColor(.separator)
    }

    func setText(_ value: String?) {
        cellLabel.text = value
    }

    func setBackgroundColor(_ color: UIColor?) {
        backgroundView?.backgroundColor = color
    }
}
