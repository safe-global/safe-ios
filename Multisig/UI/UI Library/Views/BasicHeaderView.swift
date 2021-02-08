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

    static let headerHeight: CGFloat = 44

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
    }

    func setName(_ value: String) {
        nameLabel.setAttributedText(value.uppercased(), style: .caption1)
    }
}
