//
//  ExecutionStatusPieceTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExecutionStatusPiece: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.primary)
        descriptionLabel.setStyle(.primary)
    }
}
