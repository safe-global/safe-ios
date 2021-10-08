//
//  EditCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditCell: UITableViewCell {
    @IBOutlet weak var editButton: UIButton!

    var onEdit: (() -> Void)?

    @IBAction func edit(_ sender: Any) {
        onEdit?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        editButton.setText("Edit", .primary)
    }
}
