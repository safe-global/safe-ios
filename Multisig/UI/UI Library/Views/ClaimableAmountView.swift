//
//  ClaimableAmountView.swift
//  Multisig
//
//  Created by Mouaz on 8/2/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimableAmountView: UINibView {
    @IBOutlet private weak var claimButton: UIButton!

    var onClaim: (() -> ())?
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.clear.cgColor
    }

    @IBAction func claimButtonTouched(_ sender: Any) {
        onClaim?()
    }
}
