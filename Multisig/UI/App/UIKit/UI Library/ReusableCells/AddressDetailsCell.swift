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

    static let rowHeight: CGFloat = 68
    private var address: Address?

    enum Style {
        case nameAndAddress
        case address
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addressWithTitleView.addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
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

    @objc private func copyAddress() {
        guard let address = addressWithTitleView.address else { return }
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

}
