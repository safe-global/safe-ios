//
//  SecurityStatusTableViewCell.swift
//  Multisig
//
//  Created by Mouaz on 8/17/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SecurityStatusTableViewCell: UITableViewCell {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var actionsView: ToDoListView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.title2)
        descriptionLabel.setStyle(.subheadlineSecondary)
    }

    func set(title: String,
             subTitle: String,
             imageName: String,
             actions: [(Bool, String)]) {
        titleLabel.text = title
        descriptionLabel.text = subTitle
        iconImageView.image = UIImage(named: imageName)
        actionsView.set(items: actions)
    }
}
