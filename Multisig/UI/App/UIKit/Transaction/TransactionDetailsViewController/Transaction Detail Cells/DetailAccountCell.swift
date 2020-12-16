//
//  DetailAccountCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailAccountCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    func setAccount(address: String, label: String? = nil, title: String? = nil) {
        setAccount(address: .init(exactly: address), label: label, title: title)
    }

    func setAccount(address: Address, label: String? = nil, title: String? = nil) {
        addressInfoView.setAddress(address, label: label)
        addressInfoView.setTitle(title)
    }
}
