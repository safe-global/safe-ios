//
//  InfoBoxView.swift
//  Multisig
//
//  Created by Vitaly on 15.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoBoxView: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView.layer.cornerRadius = 6
        backgroundView.backgroundColor = .infoBackground
        messageLabel.setStyle(.callout)
    }

    func setText(_ text: String) {
        messageLabel.text = text
    }

    func setText(_ text: String,
                 backgroundColor: UIColor = .infoBackground,
                 hideIcon: Bool = false,
                 icon: UIImage? = nil
    ) {
        setText(
            NSAttributedString(string: text),
            backgroundColor: backgroundColor,
            hideIcon: hideIcon,
            icon: icon
        )
    }

    func setText(_ text: NSAttributedString,
                 backgroundColor: UIColor = .infoBackground,
                 hideIcon: Bool = false,
                 icon: UIImage? = nil
    ) {
        messageLabel.attributedText = text
        backgroundView.backgroundColor = backgroundColor
        iconImageView.isHidden = hideIcon
        if let icon = icon {
            iconImageView.image = icon
        }
    }
}
