//
//  ReviewSendFundsTransactionHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/10/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewSendFundsTransactionHeaderTableViewCell: UITableViewCell {

    @IBOutlet private weak var tokenInfoView: TokenInfoView!
    @IBOutlet private weak var fromAddressInfoView: AddressInfoView!
    @IBOutlet private weak var toAddressInfoView: AddressInfoView!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var fromLabel: UILabel!
    @IBOutlet private weak var toLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        toLabel.setStyle(.headlineSecondary)
        fromLabel.setStyle(.headlineSecondary)
        amountLabel.setStyle(.headlineSecondary)
    }

    func setFromAddress(_ address: Address, label: String?, prefix: String?) {
        fromAddressInfoView.setAddress(address, label: label, prefix: prefix)
    }

    func setToAddress(_ address: Address, label: String?, imageUri: URL?, prefix: String?) {
        toAddressInfoView.setAddress(address, label: label, imageUri: imageUri, prefix: prefix)
    }

    func setToken(amount: String, symbol: String, fiatBalance: String?, image url: URL?) {
        tokenInfoView.setText("\(amount) \(symbol)", style: .headline)
        tokenInfoView.setDetail(fiatBalance, style: .subheadline)
        tokenInfoView.setImage(url)
    }
}
