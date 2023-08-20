//
//  InfoFooterTableViewCell.swift
//  Multisig
//
//  Created by Mouaz on 8/19/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoTableFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!

    static let estimatedHeight: CGFloat = 36
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.footnote)
    }
}
