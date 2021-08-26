//
//  OwnerKeysListTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OwnerKeysListTableViewCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()

        addressInfoView.setDetailImage(nil)
        addressInfoView.copyEnabled = false
    }

    func set(address: Address, title: String, type: KeyType) {
        addressInfoView.setAddress(address, label: title, badgeName: type.imageName)
    }
}
