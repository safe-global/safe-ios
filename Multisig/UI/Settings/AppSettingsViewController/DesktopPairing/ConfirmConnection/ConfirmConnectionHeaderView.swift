//
//  ConfirmConnectionHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmConnectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var headerLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.title3)
    }
}
