//
//  WarningView.swift
//  Multisig
//
//  Created by Moaaz on 4/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WarningView: UINibView {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet weak var leftBar: UIView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!

    var onClick: (() ->())?
    override func commonInit() {
        super.commonInit()
        clipsToBounds = true
        layer.cornerRadius = 8

        actionButton.setTitle("", for: .normal)
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.subheadline)

        leftBar.isHidden = true
        contentStackView.spacing = 16
    }

    func set(image: UIImage? = nil,
             title: String? = nil,
             description: String? = nil,
             backgroundColor: UIColor = .warningBackground) {
        assert(title != nil || description != nil)
        
        if let image = image {
            iconImageView.image = image
        }

        titleLabel.text = title
        titleLabel.isHidden = title == nil

        descriptionLabel.text = description
        descriptionLabel.isHidden = description == nil
        self.backgroundColor = backgroundColor
        layoutIfNeeded()
    }

    // Do everything required for delegate warning if true
    func showLeftBar(_ show: Bool) {
        leftBar.isHidden = !show
        if show {
            contentStackView.spacing = 8
            titleLabel.hyperLinkLabel("\(titleLabel.text!)\u{00A0}", linkText: "Learn More", linkIcon: nil)
            titleLabel.adjustsFontSizeToFitWidth = true
            topMargin.constant = 12
            bottomMargin.constant = 12
        } else {
            contentStackView.spacing = 16
            titleLabel.adjustsFontSizeToFitWidth = false
        }
    }

    @IBAction func actionButtonClicked(_ sender: Any) {
        onClick?()
    }
}
