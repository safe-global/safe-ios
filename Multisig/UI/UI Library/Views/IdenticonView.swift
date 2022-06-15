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
    @IBOutlet weak var ownerCountFrameView: CircleView!
    @IBOutlet weak var ownerCountLabel: UILabel!

    @IBOutlet weak var identiconLeading: NSLayoutConstraint!

    override func commonInit() {
        super.commonInit()

        badgeFrameView.clipsToBounds = true
        badgeFrameView.layer.borderColor = UIColor.whiteOrBlack.cgColor
        badgeFrameView.backgroundColor = .labelSecondary

        ownerCountFrameView.clipsToBounds = true
        ownerCountFrameView.layer.borderColor = UIColor.whiteOrBlack.cgColor
        ownerCountFrameView.backgroundColor = .primaryDisabled

        ownerCountLabel.setStyle(.footnote2)
        ownerCountLabel.textColor = .primary
    }

    func set(address: Address, imageURL: URL? = nil, badgeName: String? = nil, reqConfirmations: Int? = nil, owners: Int? = nil) {
        identiconImageView.setCircleImage(url: imageURL, address: address)
        if let badgeName = badgeName {
            badgeImageView.image = UIImage(named: badgeName)
        }

        badgeFrameView.isHidden = badgeName == nil

        if let reqConfirmations = reqConfirmations,
           let owners = owners {
            ownerCountLabel.text = " \(reqConfirmations)/\(owners) "
            ownerCountFrameView.isHidden = false
        } else {
            ownerCountFrameView.isHidden = true
        }
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
