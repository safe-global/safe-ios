//
//  OwnerHeaderView.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class OwnerHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    static let headerHeight: CGFloat = 44

    var onAdd: (() -> Void)?


    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        numberLabel.text = nil
        addButton.setText("", .plain)
    }

    func setNumber(_ value: Int?) {
        numberLabel.setAttributedText(value != nil ? String(value!) : "", style: .caption2Tertiary)
    }

    func setName(_ value: String) {
        nameLabel.setAttributedText(value.uppercased(), style: .caption2Tertiary)
    }

    @IBAction func didTapAddButton(_ sender: Any) {
        onAdd?()
    }
}
