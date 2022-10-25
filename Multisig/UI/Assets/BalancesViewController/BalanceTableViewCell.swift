//
//  BalanceTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class BalanceTableViewCell: UITableViewCell {
    @IBOutlet private weak var cellMainLabel: UILabel!
    @IBOutlet private weak var cellDetailLabel: UILabel!
    @IBOutlet private weak var cellSubDetailLabel: UILabel!
    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var browseIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellMainLabel.setStyle(.headline)
        cellDetailLabel.setStyle(.headline)
        cellSubDetailLabel.setStyle(.footnoteSecondary)

        for label in [cellMainLabel, cellDetailLabel, cellSubDetailLabel] {
            label?.text = nil
        }
        cellImageView.image = nil
    }

    func setMainText(_ value: String) {
        cellMainLabel.text = value
    }

    func setDetailText(_ value: String) {
        cellDetailLabel.text = value
    }

    func setSubDetailText(_ value: String) {
        cellSubDetailLabel.text = value
    }

    func setImage(with url: URL?, placeholder: UIImage) {
        cellImageView.setCircleShapeImage(url: url, placeholder: placeholder)
    }

    func setImage(_ image: UIImage) {
        cellImageView.image = image
    }

    func setBrowsingEnabled(_ enabled: Bool = false) {
        browseIcon.isHidden = !enabled
    }
}
