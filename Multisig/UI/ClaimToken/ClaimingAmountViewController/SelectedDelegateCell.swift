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
        addressContainer.layer.borderColor = UIColor.border.cgColor
        headerLabel.setStyle(.secondary)
        detailLabel.setStyle(.footnote4)
        editButton.setText("Edit", .primary)
        headerLabel.text = "Delegating to:"
        detailLabel.text = "You only delegate your voting power and not the ownership over your tokens."
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
}
