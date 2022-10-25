//
//  BackupKeyTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 4/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupKeyTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var backupButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    var onClick: (() -> ())?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.body)
        backupButton.setText("Back up now", .filled)
    }

    @IBAction func backupButtonTouched(_ sender: Any) {
        onClick?()
    }
}
