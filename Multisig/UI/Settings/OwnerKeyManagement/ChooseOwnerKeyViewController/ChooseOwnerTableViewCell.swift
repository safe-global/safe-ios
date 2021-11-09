//
//  ChooseOwnerTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 3/11/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseOwnerTableViewCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.copyEnabled = false
    }

    func set(address: Address, title: String, badgeName: String?) {
        addressInfoView.setAddress(address, label: title, badgeName: badgeName)
    }
}
