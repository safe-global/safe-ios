//
//  BasicCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class BasicCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var disclosureImageView: UIImageView!

    static let rowHeight: CGFloat = 60

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.primary)
        detailLabel.setStyle(.secondary)
        setDetail(nil)
    }

    func setTitle(_ value: String?) {
        titleLabel.text = value
    }

    func setDetail(_ value: String?) {
        detailLabel.text = value
    }

    func setDisclosureImage(_ image: UIImage?) {
        disclosureImageView.image = image
    }

    func setDisclosureImageTintColor(_ tintColor: UIColor) {
        disclosureImageView.tintColor = tintColor
    }
}
