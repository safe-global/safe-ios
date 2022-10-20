//
//  DappNameTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 7/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class IcommingDappInteractionRequestHeaderTableViewCell: UITableViewCell {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var fromAddressInfoView: AddressInfoView!
    @IBOutlet private weak var toAddressInfoView: AddressInfoView!
    @IBOutlet private weak var fromLabel: UILabel!
    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet weak var dappInfoContainerView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        dappNameLabel.setStyle(.headline)
        toLabel.setStyle(.headlineSecondary)
        fromLabel.setStyle(.headlineSecondary)
    }

    func setFromAddress(_ address: Address, label: String?, prefix: String?, title: String? = "From") {
        fromAddressInfoView.setAddress(address, label: label, prefix: prefix)
        fromLabel.text = title
    }

    func setToAddress(_ address: Address, label: String?, imageUri: URL?, prefix: String?, title: String? = "To") {
        toAddressInfoView.setAddress(address, label: label, imageUri: imageUri, prefix: prefix)
        toLabel.text = title
    }

    func setDapp(imageURL: URL? = nil, name: String) {
        dappNameLabel.text = name
        dappImageView.kf.setImage(with: imageURL, placeholder: UIImage(named: "ico-empty-circle"))
    }

    func setDappInfo(hidden: Bool) {
        dappInfoContainerView.isHidden = hidden
    }
}
