//
//  DefaultKeyTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DefaultKeyTableViewCell: UITableViewCell {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var leftLabel: UILabel!
    @IBOutlet private weak var addressView: AddressInfoView!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var cardView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        leftLabel.setStyle(.body)
        detailLabel.setStyle(.body)
        addressView.copyEnabled = false
        iconImageView.tintColor = .primary
    }

    func setHeader(_ text: String?) {
        headerLabel.text = text
    }

    func setLeft(_ text: String?) {
        leftLabel.text = text
    }

    func setDetail(_ text: String?) {
        detailLabel.text = text
        detailLabel.isHidden = text == nil
    }

    func setSelected(_ selected: Bool) {
        iconImageView.alpha = selected ? 1 : 0
    }

    func setAddress(_ value: Address, label: String? = nil) {
        addressView.setAddress(value, label: label)
    }

    func setEnabled(_ enabled: Bool) {
        contentView.alpha = enabled ? 1 : 0.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            let anim = CAKeyframeAnimation(keyPath: "transform.scale")
            anim.values = [1.0, 1.03, 0.98, 1.0]
            anim.duration = 0.4
            anim.calculationMode = .cubic
            cardView.layer.add(anim, forKey: "Bounce")
        }
    }
}
