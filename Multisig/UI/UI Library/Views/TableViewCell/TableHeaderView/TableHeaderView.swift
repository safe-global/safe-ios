//
//  SelectNetworkTableHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TableHeaderView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!

    func set(_ title: String, style: GNOTextStyle = .headline2) {
        titleLabel.text = title
        titleLabel.setStyle(style)
    }
}
