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
    @IBOutlet weak var badgeFrameView: CircleView!

    override func commonInit() {
        super.commonInit()
        badgeFrameView.clipsToBounds = true
        badgeFrameView.layer.borderColor = UIColor.whiteOrBlack.cgColor
        badgeFrameView.backgroundColor = .labelSecondary
    }

    func set(address: Address, imageURL: URL? = nil, badgeName: String? = nil) {
        identiconImageView.setCircleImage(url: imageURL, address: address)
        if let badgeName = badgeName {
            badgeImageView.image = UIImage(named: badgeName)
        }

        badgeFrameView.isHidden = badgeName == nil
    }
}

extension KeyType {
    var imageName: String {
        switch self {
        case .deviceImported:
            return "ico-key-type-key"
        case .deviceGenerated:
            return "ico-key-type-seed"
        case .walletConnect:
            return "ico-key-type-walletconnect"
        case .ledgerNanoX:
            return "ico-key-type-ledger"
        }
    }
}
