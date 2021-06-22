//
//  ImportKeyBannerCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportKeyBannerCell: UITableViewCell {
    @IBOutlet private weak var bannerView: BannerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        bannerView.headerText = "Add owner key"
        bannerView.bodyText = "We added signing support to the app! Now you can import your owner key and sign transactions on the go."
        bannerView.buttonText = "Add owner key now"
    }
}
