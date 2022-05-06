//
//  OwnerActionView.swift
//  Multisig
//
//  Created by Vitaly on 26.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class OwnerActionView: UINibView {

    @IBOutlet weak var blockie: IdenticonView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var actionTag: TagView!


    override func commonInit() {
        super.commonInit()
        nameLabel.setStyle(.primary)
        addressLabel.setStyle(.tertiary)
    }

    func set(owner: AddressInfo, action: OwnerAction) {
        blockie.set(address: owner.address)
        nameLabel.text = owner.name
        addressLabel.text = owner.address.ellipsized()
        switch action {
        case .addingOwner:
            actionTag.set(title: "Adding owner", style: .footnote2, backgroundColor: .backgroundPositive, textColor: .primary)
        case .removingOwner:
            actionTag.set(title: "Removing owner", style: .footnote2, backgroundColor: .backgroundPrimary, textColor: .labelSecondary)
        }
    }
}

enum OwnerAction {
    case addingOwner, removingOwner
}
