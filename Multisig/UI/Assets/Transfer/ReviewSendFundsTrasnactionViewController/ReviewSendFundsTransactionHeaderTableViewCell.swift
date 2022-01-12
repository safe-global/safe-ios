//
//  ReviewSendFundsTransactionHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/10/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewSendFundsTransactionHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var tokenInfoView: TokenInfoView!
    @IBOutlet private weak var fromAddressInfoView: AddressInfoView!
    @IBOutlet private weak var toAddressInfoView: AddressInfoView!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var fromLabel: UILabel!
    @IBOutlet private weak var toLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        toLabel.setStyle(.secondary)
        fromLabel.setStyle(.secondary)
        amountLabel.setStyle(.secondary)
    }

    func setFromAddress(_ address: Address, label: String?, prefix: String?) {
        fromAddressInfoView.setAddress(address, label: label, prefix: prefix)
    }

    func setToAddress(_ address: Address, label: String?, imageUri: URL?, prefix: String?) {
        toAddressInfoView.setAddress(address, label: label, imageUri: imageUri, prefix: prefix)
    }

    func setToken(text: String, details: String?, image url: URL?) {
        tokenInfoView.setText(text, style: .title4)
        tokenInfoView.setDetail(details, style: .footnote4)
        tokenInfoView.setImage(url)
    }
}
