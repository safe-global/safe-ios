//
//  IdenticonView.swift
//  Multisig
//
//  Created by Moaaz on 8/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class IdenticonView: UINibView {
    @IBOutlet private weak var identiconImageView: UIImageView!
    @IBOutlet private weak var badgeImageView: UIImageView!

    override func commonInit() {
        super.commonInit()
        badgeImageView.clipsToBounds = true
        badgeImageView.layer.cornerRadius = badgeImageView.frame.height / 2
    }

    func set(address: Address, imageURL: URL? = nil, badgeName: String? = nil) {
        identiconImageView.setCircleImage(url: imageURL, address: address)
        if let badgeName = badgeName {
            badgeImageView.image = UIImage(named: badgeName)
        }

        badgeImageView.isHidden = badgeName != nil
    }
}
