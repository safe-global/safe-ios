//
//  LoadingView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadingView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = nil
        titleLabel.setStyle(.body)
        backgroundColor = .backgroundPrimary
    }

    func set(title: String) {
        titleLabel.text = title
    }
}
