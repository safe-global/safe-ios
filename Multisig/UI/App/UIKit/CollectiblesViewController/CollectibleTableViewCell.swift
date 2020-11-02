//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(collectible: CollectibleViewModel) {
        nameLabel.text = collectible.name
    }
}
