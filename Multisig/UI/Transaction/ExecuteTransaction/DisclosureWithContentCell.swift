//
//  DisclosureWithContentCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class DisclosureWithContentCell: UITableViewCell {

    // body label left-aligned, vertically centered
    @IBOutlet weak var cellLabel: UILabel!
    // content spans remaining horizontal space
    @IBOutlet weak var detailContentView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellLabel.setStyle(.headline)
    }

    func setText(_ value: String?) {
        cellLabel.text = value
    }

    func setContent(_ view: UIView?) {
        // clear subviews
        for v in detailContentView.subviews {
            v.removeFromSuperview()
        }
        guard let view = view else { return }

        view.translatesAutoresizingMaskIntoConstraints = false

        detailContentView.addSubview(view)

        detailContentView.addConstraints([
            view.leadingAnchor.constraint(equalTo: detailContentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: detailContentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: detailContentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: detailContentView.bottomAnchor)
        ])
    }

    func setBackgroundColor(_ color: UIColor?) {
        self.backgroundColor = color
    }
}
