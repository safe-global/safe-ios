//
//  ClaimableAmountView.swift
//  Multisig
//
//  Created by Mouaz on 8/2/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimableAmountView: UINibView {
    @IBOutlet private weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        label.setStyle(.headline)
    }

    func set(value: String) {
        label.text = value
    }
}
