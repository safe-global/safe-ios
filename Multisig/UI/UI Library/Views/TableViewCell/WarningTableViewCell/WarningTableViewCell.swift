//
//  WarningTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 5/19/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WarningTableViewCell: UITableViewCell {

    @IBOutlet weak var warningView: WarningView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func set(image: UIImage? = nil, title: String? = nil, description: String? = nil) {
        warningView.set(image: image, title: title, description: description)
        layoutIfNeeded()
    }
}
