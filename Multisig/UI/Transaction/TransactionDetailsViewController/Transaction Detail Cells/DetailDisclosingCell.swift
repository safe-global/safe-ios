//
//  DetailDisclosingCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailDisclosingCell: UITableViewCell {
    var action: () -> Void = {}

    @IBOutlet private weak var bodyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        bodyLabel.setStyle(.headline)
    }

    func setText(_ text: String) {
        bodyLabel.text = text
    }
}
