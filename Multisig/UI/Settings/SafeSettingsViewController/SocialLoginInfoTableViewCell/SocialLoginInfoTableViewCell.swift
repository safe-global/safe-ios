//
//  SocialLoginInfoTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 14.07.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SocialLoginInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var infoBox: InfoBoxView!
    private var onAddOwner: (() -> ())? = nil
    private var onLearnMore: (() -> ())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(onAddOwner: (() -> ())?, onLearnMore: (() -> ())?) {
        self.onAddOwner = onAddOwner
        self.onLearnMore = onLearnMore
        infoBox.setText(
            "Add extra owner keys to protect your funds and be able to regain access to your account.",
            backgroundColor: .warningBackground,
            icon: UIImage(named: "ico-shield-infobox")?.withTintColor(.warning)
        )
        infoBox.addActionSecondary(title: "Learn more", action: onLearnMore)
        infoBox.addActionPrimary(title: "Add owner", action: onAddOwner)
    }
}
