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
    @IBOutlet weak var delegateWarning: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.copyEnabled = false
        delegateWarning.isHidden = true
    }

    func setAddress(_ address: Address, label: String?, imageUri: URL?, prefix: String?) {
        addressInfoView.setAddress(address, label: label, imageUri: imageUri, prefix: prefix)
    }

    func setAction(_ text: String?) {
        addressInfoView.setTitle(text)
    }

    func setDelegateWarning(_ showDelegateWarning: Bool) {
        delegateWarning.isHidden = !showDelegateWarning
    }
}
