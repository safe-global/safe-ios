//
//  MultiSendRowTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MultiSendRowTableViewCell: UITableViewCell {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var actionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.copyEnabled = false
        addressInfoView.setDetailImage(nil)
        actionLabel.setStyle(.primary)
    }

    func setAddress(_ address: Address, label: String?, imageUri: URL?) {
        addressInfoView.setAddress(address, label: label, imageUri: imageUri)
    }

    func setAction(_ text: String?) {
        actionLabel.text = text
    }
}
