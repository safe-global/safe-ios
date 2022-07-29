//
//  GuardianTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianTableViewCell: UITableViewCell {
    weak var tableView: UITableView?
    
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = 10
        containerView.layer.borderColor = UIColor.border.cgColor
        descriptionLabel.setStyle(.secondary)
    }

    func set(guardian: Guardian) {

        addressInfoView.setAddressOneLine(
            guardian.address,
            ensName: guardian.ensName,
            hideAddress: false,
            label: guardian.name,
            imageUri: guardian.imageURL,
            badgeName: nil,
            prefix: nil)

        addressInfoView.copyEnabled = false
        
        descriptionLabel.text = guardian.reason
    }
}
