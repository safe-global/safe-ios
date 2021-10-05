//
//  ConfirmConnectionHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmConnectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var headerLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.title3)
    }

    func setImage(url: URL?) {
        headerImageView.kf.setImage(with: url, placeholder: UIImage(named: "ico-empty-circle"))
    }

    func setTitle(_ text: String) {
        headerLabel.text = text
    }
}
