//
//  CollectiblesHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectiblesHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var nameLabel: UILabel!

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(collectibleSection: CollectibleListSection) {
        nameLabel.text = collectibleSection.name
    }
}
