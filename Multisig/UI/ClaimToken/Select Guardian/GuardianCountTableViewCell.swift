//
//  GuardianCountTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 28.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianCountTableViewCell: UITableViewCell {

    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        countLabel.setStyle(.body)
    }

    func setCount(_ count: Int) {
        if count > 1 {
            countLabel.text = "\(count) delegates"
        } else {
            countLabel.text = "\(count) delegate"
        }
    }
}
