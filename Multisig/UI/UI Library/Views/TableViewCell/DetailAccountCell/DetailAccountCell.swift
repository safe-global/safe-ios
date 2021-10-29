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
    @IBOutlet private weak var qrCodeView: QRCodeView!

    func setAccount(address: Address, label: String? = nil, title: String? = nil, imageUri: URL? = nil, badgeName: String? = nil, showQRCode: Bool = false, showExternalLink: Bool = true) {
        addressInfoView.setAddress(address, label: label, imageUri: imageUri, badgeName: badgeName)
        addressInfoView.setTitle(title)
        qrCodeView.isHidden = !showQRCode
        qrCodeView.value = address.checksummed
        if !showExternalLink {
            addressInfoView.setDetailImage(nil)
        }
    }
}
