//
//  PairingOwnerKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PairingOwnerKeyCell: UITableViewCell {
    @IBOutlet private weak var addressView: AddressInfoView!
    @IBOutlet private weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        iconImageView.tintColor = .button
        addressView.setDetailImage(nil)
        addressView.copyEnabled = false
    }

    func configure(keyInfo: KeyInfo, selected: Bool) {
        addressView.setAddress(keyInfo.address, label: keyInfo.displayName)
        iconImageView.alpha = selected ? 1 : 0
    }    
}
