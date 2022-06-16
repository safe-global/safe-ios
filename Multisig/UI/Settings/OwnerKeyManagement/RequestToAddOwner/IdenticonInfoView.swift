//
//  KeyInfoView.swift
//  Multisig
//
//  Created by Vitaly on 13.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class IdenticonInfoView: UINibView {

    @IBOutlet private weak var blockie: IdenticonView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    override func commonInit() {
        super.commonInit()

        nameLabel.setStyle(.primary)
        addressLabel.setStyle(.tertiary)
    }

    func set(owner: AddressInfo, badgeName: String? = nil, reqConfirmations: Int? = nil, ownerCount: Int? = nil) {

        blockie.set(address: owner.address, badgeName: badgeName, reqConfirmations: reqConfirmations, owners: ownerCount)

        if let name = owner.name {
            nameLabel.text = name
        } else {
            nameLabel.isHidden = true
        }
        addressLabel.text = owner.address.ellipsized()
    }
}

