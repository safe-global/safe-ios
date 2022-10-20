//
//  DetailAccountAndTextCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailAccountAndTextCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var textTitleLabel: UILabel!
    @IBOutlet private weak var textDetailsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        textTitleLabel.setStyle(.headline)
        textDetailsLabel.setStyle(.body)
    }

    func setAccount(address: Address, label: String?, title: String?, imageUri: URL?, browseURL: URL?, prefix: String?) {
        addressInfoView.setTitle(title)
        addressInfoView.setAddress(address, label: label, imageUri: imageUri, browseURL: browseURL, prefix: prefix)
    }

    func setText(title: String, details: String) {
        textTitleLabel.text = title
        textDetailsLabel.text = details
    }
}
