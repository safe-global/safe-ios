//
//  ReplaceOwnerTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReplaceOwnerTableViewCell: UITableViewCell {

    @IBOutlet weak var newOwnerView: OwnerActionView!
    @IBOutlet weak var oldOwnerView: OwnerActionView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func set(newOwner: AddressInfo, oldOwner: AddressInfo) {
        newOwnerView.set(owner: newOwner, action: .addingOwner)
        oldOwnerView.set(owner: oldOwner, action: .replacingOwner)
    }
}
