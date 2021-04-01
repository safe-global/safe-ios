//
//  MultiSendRowTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MultiSendRowTableViewCell: UITableViewCell {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var actionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.setStyle(.primary)
        actionLabel.setStyle(.primary)
    }

    func setIdenticon(_ text: String) {
        identiconView.setAddress(text)
    }

    func setIcon(_ image: UIImage?) {
        identiconView.image = image
    }

    func setMainText(_ text: String?) {
        mainLabel.text = text
    }

    func setAction(_ text: String?) {
        actionLabel.text = text
    }
}
