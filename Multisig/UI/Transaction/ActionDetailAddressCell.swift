//
//  ActionDetailAddressCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailAddressCell: ActionDetailTableViewCell {
    @IBOutlet private weak var addressView: AddressInfoView!
    func setAddress(_ value: Address) {
        addressView.setAddress(value, label: nil, imageUri: nil)
    }
}
