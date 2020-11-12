//
//  AddressCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressDetailsCell: UITableViewCell {
    @IBOutlet private weak var addressWithTitleView: AddressWithTitleView!

    private var style: Style = .nameAndAddress
    var onViewDetails: (() -> Void)?

    static let rowHeight: CGFloat = 60

    enum Style {
        case nameAndAddress
        case address
    }

    @IBAction func viewAddressDetails() {
        onViewDetails?()
    }

    func setAddress(_ value: Address) {
        addressWithTitleView.setAddress(value)
    }

    func setName(_ value: String) {
        addressWithTitleView.setName(value)
    }

    func setStyle(_ value: Style) {
        switch value {
        case .nameAndAddress:
            addressWithTitleView.setStyle(.nameAndAddress)
        case .address:
            addressWithTitleView.setStyle(.address)
        }
    }
}
