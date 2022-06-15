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
    @IBOutlet private weak var warningView: WarningView!

    func setAccount(address: Address, label: String? = nil,
                    title: String? = nil,
                    imageUri: URL? = nil,
                    badgeName: String? = nil,
                    showQRCode: Bool = false,
                    copyEnabled: Bool = true,
                    browseURL: URL? = nil,
                    prefix: String? = nil,
                    titleStyle: GNOTextStyle = .headline,
                    showDelegateWarning: Bool = false) {
        addressInfoView.setAddress(address, label: label,
                                   imageUri: imageUri,
                                   badgeName: badgeName,
                                   browseURL: browseURL,
                                   prefix: prefix)
        addressInfoView.setTitle(title, style: titleStyle)
        qrCodeView.isHidden = !showQRCode
        qrCodeView.value = address.checksummed

        warningView.isHidden = !showDelegateWarning
        warningView.set(title: "Unexpected DelegateCall")
        warningView.showLeftBar(true)
        warningView.onClick = {
            let url = URL(string: "https://help.gnosis-safe.io/en/articles/6302452-unexpected-delegate-calls")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        addressInfoView.copyEnabled = copyEnabled
    }
}
