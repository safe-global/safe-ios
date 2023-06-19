//
//  SelectNetworkTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectNetworkTableViewCell: UITableViewCell {
    @IBOutlet private weak var colorImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var infoView: InfoBoxView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = 10
        nameLabel.setStyle(.headline)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // changing here to react to dark/light color change
        containerView.layer.borderColor = UIColor.border.cgColor
    }

    func setText(_ text: String?) {
        nameLabel.text = text
    }

    func setIndicatorColor(hex: String) {
        setIndicatorColor(UIColor(hex: hex))
    }

    func setIndicatorColor(_ color: UIColor?) {
        colorImageView.tintColor = color
    }

    func setInfo(_ text: NSAttributedString?) {
        if let text = text {
            infoView.isHidden = false
            infoView.setText(text, backgroundColor: .backgroundLightGreen, hideIcon: true)
        } else {
            infoView.isHidden = true
        }

        layoutIfNeeded()
    }
}
