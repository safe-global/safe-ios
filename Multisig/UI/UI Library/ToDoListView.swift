//
//  ToDoListView.swift
//  Multisig
//
//  Created by Mouaz on 8/17/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ToDoListView: UINibView {

    @IBOutlet weak var actionsContainer: UIStackView!

    private var items: [(selected: Bool, text: String)] = []

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func set(items: [(Bool, String)]) {
        self.items = items
        setNeedsLayout()
        updateUI()
    }

    private func updateUI() {
        actionsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        items.forEach {

            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.distribution = .fill
            row.spacing = 8

            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.addConstraint(NSLayoutConstraint(item: imageView,
                                                              attribute: .width,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .width,
                                                              multiplier: 1,
                                                              constant: 24))

            if $0.selected {
                imageView.image = UIImage(named: "ico-checkmark")?.withTintColor(.baseSuccess, renderingMode: .alwaysOriginal)
            } else {
                imageView.image = UIImage(named: "ico-emptymark-off")?.withTintColor(.icon, renderingMode: .alwaysOriginal)
            }

            let tipLabel = UILabel()
            tipLabel.setStyle(.subheadline)
            tipLabel.numberOfLines = 0
            tipLabel.text = $0.text

            row.addArrangedSubview(imageView)
            row.addArrangedSubview(tipLabel)

            actionsContainer.addArrangedSubview(row)
        }
    }
}
