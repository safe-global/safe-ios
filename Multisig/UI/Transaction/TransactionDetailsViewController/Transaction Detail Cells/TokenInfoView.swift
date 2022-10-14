//
//  TokenInfoView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenInfoView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        setDetail(nil)
        setTitle(nil)
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    func setImage(_ url: URL?, placeholder: UIImage? = nil) {
        imageView.setCircleShapeImage(url: url, placeholder: placeholder ?? UIImage(named: "ico-token-placeholder"))
    }

    func setText(_ text: String, style: GNOTextStyle = .headline) {
        textLabel.text = text
        textLabel.setStyle(style)
    }

    func setTitle(_ value: String?, style: GNOTextStyle = .headlineSecondary) {
        titleLabel.text = value
        titleLabel.setStyle(style)
        titleLabel.isHidden = value == nil
    }

    func setDetail(_ text: String?, style: GNOTextStyle = .footnote) {
        detailLabel.text = text
        detailLabel.setStyle(style)
        detailLabel.isHidden = text == nil
    }
}
