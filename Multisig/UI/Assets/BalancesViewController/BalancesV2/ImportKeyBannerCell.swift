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
        bannerView.bodyText = "Did you know that you can import your owner key to sign and execute transactions on the go?"
        bannerView.buttonText = "Add owner key now"
    }
}
