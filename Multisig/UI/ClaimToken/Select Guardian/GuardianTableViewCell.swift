//
//  GuardianTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianTableViewCell: UITableViewCell {    
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var checkMarkView: UIImageView!

    var borderColor: UIColor = .border {
        didSet {
            setNeedsLayout()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = 10
        descriptionLabel.setStyle(.body)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // changing here to react to dark/light color change
        containerView.layer.borderColor = borderColor.cgColor
    }

    func set(guardian: Guardian, selected: Bool = false) {
        addressInfoView.setAddressOneLine(
            guardian.address.address,
            ensName: guardian.ens,
            hideAddress: false,
            label: guardian.name,
            imageUri: guardian.imageURL,
            placeholderImage: "ico-no-delegate-placeholder",
            badgeName: nil,
            prefix: nil)

        addressInfoView.copyEnabled = false
        descriptionLabel.text = guardian.reason

        borderColor = selected ? .borderSelected : .border
        checkMarkView.isHidden = !selected

        layoutIfNeeded()
    }
}
