//
//  TitledMiniPieceView.swift
//  Multisig
//
//  Created by Moaaz on 2/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TitledMiniPieceView: UINibView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
    }

    func setTitle(_ value: String?) {
        titleLabel.text = value
    }

    func setContent(_ view: UIView?) {
        // clear subviews
        for v in contentView.subviews {
            v.removeFromSuperview()
        }
        guard let view = view else { return }

        view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(view)

        contentView.addConstraints([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
