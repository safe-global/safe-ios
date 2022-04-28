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


    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.setStyle(.primary)
        addressLabel.setStyle(.tertiary)
    }

    func set(owner: KeyInfo, action: OwnerAction) {
        blockie.set(address: owner.address)
        nameLabel.text = owner.name
        addressLabel.text = owner.address.ellipsized(prefix: 4)
        switch action {
        case .addingOwner:
            actionTag.set(title: "Adding owner", style: .footnote2, backgroundColor: .backgroundPositive, textColor: .primary)
            actionTag.backgroundColor = .backgroundPositive
        case .removingOwner:
            actionTag.set(title: "Removing owner", style: .footnote2, backgroundColor = .backgroundPrimary, textColor: .labelSecondary)
            actionTag.backgroundColor = .backgroundPrimary
        }
    }
}

enum OwnerAction {
    case addingOwner, removingOwner
}
