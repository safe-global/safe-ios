//
//  AddressCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressDetailsCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    var onViewDetails: (() -> Void)?

    static let rowHeight: CGFloat = 68

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.setDisclosureButtonImage(#imageLiteral(resourceName: "ico-browse-address"))
        addressInfoView.onAddressInfoSelection = copyAddress
        addressInfoView.onDisclosureButtonAction = viewDetails
    }

    func setAddressInfo(_ addressInfo: AddressInfo) {
        addressInfoView.setAddressInfo(addressInfo)
    }

    private func copyAddress() {
        let address = addressInfoView.addressInfo.address
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    private func viewDetails() {
        onViewDetails?()
    }
}
