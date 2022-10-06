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
    @IBOutlet private weak var badgeFrameView: CircleView!
    @IBOutlet private weak var ownerCountFrameView: CircleView!
    @IBOutlet private weak var ownerCountLabel: UILabel!

    @IBOutlet weak var identiconLeading: NSLayoutConstraint!

    override func commonInit() {
        super.commonInit()

        badgeFrameView.clipsToBounds = true
        badgeFrameView.backgroundColor = .labelSecondary

        ownerCountFrameView.clipsToBounds = true
        ownerCountFrameView.backgroundColor = .primaryDisabled

        ownerCountLabel.setStyle(.footnote2)
        ownerCountLabel.textColor = .primary
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        badgeFrameView.layer.borderColor = UIColor.backgroundSecondary.cgColor
        ownerCountFrameView.layer.borderColor = UIColor.backgroundSecondary.cgColor
    }

    func set(address: Address, imageURL: URL? = nil, placeholderImage: String? = nil, badgeName: String? = nil, reqConfirmations: Int? = nil, owners: Int? = nil) {
        identiconImageView.setCircleImage(url: imageURL, placeholderName: placeholderImage, address: address)
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
        case .keystone:
            return "ico-key-type-keystone"
        }
    }
}
