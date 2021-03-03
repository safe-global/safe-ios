//
//  CardTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell {
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        bodyLabel.setStyle(.primary)
        selectionStyle = .none
    }

    func set(image: UIImage?) {
        iconImageView.image = image
    }

    func set(title: String) {
        titleLabel.text = title
    }
    
    func set(body: String) {
        bodyLabel.text = body
    }
}
