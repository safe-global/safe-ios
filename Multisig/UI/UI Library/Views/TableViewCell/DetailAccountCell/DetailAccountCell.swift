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

    func setAccount(address: Address, label: String? = nil,
                    title: String? = nil,
                    imageUri: URL? = nil,
                    badgeName: String? = nil,
                    showQRCode: Bool = false,
                    copyEnabled: Bool = true,
                    browseURL: URL? = nil,
                    prefix: String? = nil,
                    titleStyle: GNOTextStyle = .headline) {
        addressInfoView.setAddress(address, label: label,
                                   imageUri: imageUri,
                                   badgeName: badgeName,
                                   browseURL: browseURL,
                                   prefix: prefix)
        addressInfoView.setTitle(title, style: titleStyle)
        qrCodeView.isHidden = !showQRCode
        qrCodeView.value = address.checksummed

        addressInfoView.copyEnabled = copyEnabled
    }
}
