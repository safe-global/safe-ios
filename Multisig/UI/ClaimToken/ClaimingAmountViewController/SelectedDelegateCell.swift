//
//  SelectedDelegateCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectedDelegateCell: UITableViewCell {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addressView: AddressInfoView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var addressContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.body)
        detailLabel.setStyle(.footnote)
        editButton.setText("Edit", .primary)
        headerLabel.text = "Delegating to:"
        detailLabel.text = "You only delegate your voting power and not the ownership over your tokens."
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // changing here to react to dark/light color change
        addressContainer.layer.borderColor = UIColor.border.cgColor
    }

    var guardian: Guardian? {
        didSet {
            guard let guardian = guardian else {
                return
            }

            addressView.setAddress(guardian.address.address,
                                       ensName: guardian.ens,
                                       label: guardian.name,
                                       imageUri: guardian.imageURL,
                                       showIdenticon: true,
                                       badgeName: nil,
                                       browseURL: nil,
                                       prefix: nil)
            addressView.copyEnabled = false
        }
    }

    func set(address: Address, chain: Chain) {
        let (label, imageUri) = NamingPolicy.name(for: address, chainId: chain.id!)

        addressView.setAddress(address,
                                   label: label,
                                   imageUri: imageUri,
                                   showIdenticon: true,
                                   badgeName: nil,
                                   browseURL: nil,
                                   prefix: nil)
        addressView.copyEnabled = false
    }

}
