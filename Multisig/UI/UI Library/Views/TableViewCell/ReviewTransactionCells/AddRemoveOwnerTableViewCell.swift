//
//  AddRemoveOwnerTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddRemoveOwnerTableViewCell: UITableViewCell {

    @IBOutlet weak var ownerActionView: OwnerActionView!

    func set(owner: AddressInfo, action: OwnerAction, prefix: String? = nil) {
        ownerActionView.set(owner: owner, action: action, prefix: prefix)
    }
}
