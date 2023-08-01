//
//  BasicHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class BasicHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundColorView: UIView!

    static let headerHeight: CGFloat = 44

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
    }

    func setName(_ value: String, backgroundColor: UIColor = .backgroundPrimary, style: GNOTextStyle = .caption2Tertiary) {
        nameLabel.setAttributedText(value.uppercased(), style: style)
        backgroundColorView.backgroundColor = backgroundColor
    }
}
