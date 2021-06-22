//
//  CreatePasscodeBannerCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreatePasscodeBannerCell: UITableViewCell {
    @IBOutlet private weak var bannerView: BannerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        bannerView.headerText = "Create passcode"
        bannerView.bodyText = "Secure your owner keys by setting up a passcode. The passcode will be needed to open the app and sign transactions."
        bannerView.buttonText = "Create passcode now"
    }
}
