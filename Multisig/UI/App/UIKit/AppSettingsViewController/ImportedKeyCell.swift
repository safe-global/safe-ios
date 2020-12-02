//
//  ImportedKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportedKeyCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    var onRemove: (() -> Void)?

    static let rowHeight: CGFloat = 68

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.setDisclosureButtonImage(
            UIImage(systemName: "trash",
                    withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!,
            tintColor: .gnoTomato)
        addressInfoView.onAddressInfoSelection = copyAddress
        addressInfoView.onDisclosureButtonAction = removeKey
    }

    func setAddressInfo(_ addressInfo: AddressInfo) {
        addressInfoView.setAddressInfo(addressInfo)
    }

    private func copyAddress() {
        let address = addressInfoView.addressInfo.address
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    private func removeKey() {
        onRemove?()
    }
}
