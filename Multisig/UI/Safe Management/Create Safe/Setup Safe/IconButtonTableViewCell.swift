//
//  IconButtonTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class IconButtonTableViewCell: UITableViewCell {
    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellIcon.tintColor = .primary
        cellLabel.setStyle(.headline)
    }

    func setText(_ text: String?) {
        cellLabel.text = text
    }

    func setImage(_ image: UIImage?) {
        cellIcon.image = image
    }

}
