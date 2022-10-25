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

    private var networkPrefix: String? = nil

    override func commonInit() {
        super.commonInit()
        nameLabel.setStyle(.headline)
        addressLabel.setStyle(.bodyTertiary)
    }

    func set(owner: AddressInfo, action: OwnerAction, prefix: String? = nil) {
        blockie.set(address: owner.address)
        nameLabel.text = owner.name
        networkPrefix = prefix
        addressLabel.text = prependingPrefixString() + owner.address.ellipsized()

        switch action {
        case .addingOwner:
            actionTag.set(title: "Adding owner", style: .footnotePrimary, backgroundColor: .backgroundLightGreen, textColor: .primary)
        case .replacingOwner:
            actionTag.set(title: "Removing owner", style: .footnotePrimary, backgroundColor: .backgroundPrimary, textColor: .labelSecondary)
        case .removingOwner:
            actionTag.set(title: "Removing owner", style: .footnotePrimary, backgroundColor: .errorBackground, textColor: .error)
        }
    }

    private func prependingPrefixString() -> String {
        AppSettings.prependingChainPrefixToAddresses ? prefixString() : ""
    }

    private func prefixString() -> String {
        networkPrefix != nil ? "\(networkPrefix!):" : ""
    }
}

enum OwnerAction {
    case addingOwner, removingOwner, replacingOwner
}
