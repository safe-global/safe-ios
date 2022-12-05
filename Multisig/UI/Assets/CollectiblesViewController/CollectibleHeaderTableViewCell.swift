//
//  CollectibleHeaderTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 30.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleHeaderTableViewCell: UITableViewCell {

    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var headerNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerNameLabel.setStyle(.headline)
    }

    func setName(_ value: String) {
        headerNameLabel.text = value
    }

    func setImage(with URL: URL?, placeholder: UIImage) {
        if let url = URL {
            headerImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            headerImageView.image = placeholder
        }
    }
}
