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
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 10.0
        containerView.layer.shadowColor = UIColor.gnoCardShadow.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        containerView.layer.shadowRadius = 12.0
        containerView.layer.shadowOpacity = 0.7

        titleLabel.setStyle(.headline)
        bodyLabel.setStyle(.body)
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
