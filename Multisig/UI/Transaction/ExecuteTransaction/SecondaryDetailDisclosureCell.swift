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
        cellLabel.setStyle(.headline)
        backgroundView = UIView()
        setBackgroundColor(.backgroundPrimary)
    }

    func setText(_ value: String?, hideDisclousre: Bool = false) {
        cellLabel.text = value
        accessoryType = hideDisclousre ? .none : .disclosureIndicator
    }

    func setBackgroundColor(_ color: UIColor?) {
        backgroundView?.backgroundColor = color
    }
}
