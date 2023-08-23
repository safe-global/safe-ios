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
    @IBOutlet private weak var warningBanner: WarningBanner!
    @IBOutlet weak var accessoryImageView: UIImageView!

    static let headerHeight: CGFloat = 77

    func setAccount(address: Address, label: String? = nil,
                    title: String? = nil,
                    imageUri: URL? = nil,
                    badgeName: String? = nil,
                    showQRCode: Bool = false,
                    copyEnabled: Bool = true,
                    browseURL: URL? = nil,
                    prefix: String? = nil,
                    titleStyle: GNOTextStyle = .headline,
                    showDelegateWarning: Bool = false,
                    showAccessoryImage: Bool = false) {
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
            let url = App.configuration.help.unexpectedDelegateURL
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        addressInfoView.copyEnabled = copyEnabled
        accessoryImageView.isHidden = !showAccessoryImage
    }

    func setWarning(image: UIImage? = nil,
                    title: String? = nil,
                    description: String? = nil,
                    info: String? = nil,
                    accessory: UIImage? = nil,
                    backgroundColor: UIColor = .warningBackground,
                    onClick: (() ->())?) {

        warningBanner.isHidden = false
        warningBanner.set(image: image,
                          title: title,
                          description: description,
                          info: info,
                          accessory: accessory,
                          backgroundColor: backgroundColor,
                          onClick: onClick)
    }
}
