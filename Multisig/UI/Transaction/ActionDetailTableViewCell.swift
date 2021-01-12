//
//  ActionDetailTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var stackView: UIStackView!
    var onTap: () -> Void = {}

    var margins: NSDirectionalEdgeInsets {
        get { stackView.directionalLayoutMargins }
        set { stackView.directionalLayoutMargins = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset.left = CGFloat.greatestFiniteMagnitude
    }
}
