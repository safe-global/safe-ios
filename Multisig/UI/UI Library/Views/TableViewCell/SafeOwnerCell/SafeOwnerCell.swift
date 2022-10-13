//
//  SafeOwnerCell.swift
//  Multisig
//
//  Created by Vitaly on 05.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeOwnerCell: UITableViewCell {

    @IBOutlet weak var identiconView: IdenticonView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!

    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconHeightConstraint: NSLayoutConstraint!

    static let defaultIconSize: CGFloat = 36

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.setStyle(.headline)
        addressLabel.setStyle(.bodyTertiary)
        setIconSize(Self.defaultIconSize)
    }

    func setAccount(address: Address,
                    selected: Bool = false,
                    name: String? = nil,
                    imageUri: URL? = nil,
                    badgeName: String? = nil,
                    prefix: String? = nil) {

        if let name = name {
            nameLabel.isHidden = false
            nameLabel.text = name
            addressLabel.setStyle(.bodyTertiary)
        } else {
            nameLabel.isHidden = true
        }

        let prefixString = prefix != nil ? "\(prefix!):" : ""
        if let _ = name {
            addressLabel.text = prependingPrefixString(prefixString) + address.ellipsized()
        } else {
            let prefixString = prependingPrefixString(prefixString)
            addressLabel.attributedText = (prefixString + address.checksummed).highlight(prefix: prefixString.count + 6)
        }

        identiconView.set(address: address, imageURL: imageUri, badgeName: badgeName)

        checkmark.isHidden = !selected
    }

    func setIconSize(_ value: CGFloat) {
        iconWidthConstraint.constant = value
        iconHeightConstraint.constant = value
        setNeedsUpdateConstraints()
    }

    private func prependingPrefixString(_ prefixString: String) -> String {
        AppSettings.prependingChainPrefixToAddresses ? prefixString : ""
    }
}
