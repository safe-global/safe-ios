//
//  SafeTokenBannerTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 23.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeTokenBannerTableViewCell: UITableViewCell {

    @IBOutlet weak var banner: SafeTokenBanner!

    var onClaim: () -> Void = {}
    var onClose: () -> Void = {}

    func setupBanner(onClaim: @escaping () -> Void, onClose: @escaping () -> Void) {
        banner.onClaim = onClaim
        banner.onClose = onClose
    }
}
