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


    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        numberLabel.text = nil
        addButton.setText("", .plain)
    }

    func setNumber(_ value: Int?) {
        numberLabel.setAttributedText(value != nil ? String(value!) : "", style: .caption1)
        numberLabel.textColor = .labelSecondary
    }

    func setName(_ value: String) {
        nameLabel.setAttributedText(value.uppercased(), style: .caption1)
    }

    @IBAction func didTapAddButton(_ sender: Any) {
        //TODO: start add owner flow
    }
}
