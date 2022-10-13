//
//  ErrorTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ErrorTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellLabel.setStyle(.calloutError)
    }

    func setText(_ text: String?) {
        cellLabel.text = text
    }
    
}
