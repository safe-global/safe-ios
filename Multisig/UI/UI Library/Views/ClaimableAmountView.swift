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
    @IBOutlet private weak var claimButton: UIButton!

    var onClaim: (() -> ())?
    override func awakeFromNib() {
        super.awakeFromNib()
        label.setStyle(.headline)
    }

    func set(value: String) {
        label.text = value
    }

    @IBAction func claimButtonTouched(_ sender: Any) {
        onClaim?()
    }
}
