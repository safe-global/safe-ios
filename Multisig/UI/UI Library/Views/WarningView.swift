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
    @IBOutlet weak var leftBar: UIImageView!
    @IBOutlet weak var actionButton: UIButton!

    var onClick: (() ->())?
    override func commonInit() {
        super.commonInit()
        clipsToBounds = true
        backgroundColor = .backgroundTertiary
        layer.cornerRadius = 4

        actionButton.setTitle("", for: .normal)
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.secondary)

        //TODO: Add orange line on the left
        leftBar.isHidden = true
        //TODO: Add URL with text Read More


        
    }

    func set(image: UIImage? = nil, title: String? = nil, description: String? = nil) {
        assert(title != nil || description != nil)
        
        if let image = image {
            iconImageView.image = image
        }

        titleLabel.text = title
        titleLabel.isHidden = title == nil

        descriptionLabel.text = description
        descriptionLabel.isHidden = description == nil
    }

    func showLeftBar(_ show: Bool) {
        leftBar.isHidden = !show
    }

    @IBAction func actionButtonClicked(_ sender: Any) {
        onClick?()
    }
}
