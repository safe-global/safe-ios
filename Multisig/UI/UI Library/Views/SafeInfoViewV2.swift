//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 1/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeInfoViewV2: UINibView {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressInfoView: AddressInfoView!

    private(set) var address: Address!
    private(set) var label: String?

    override func commonInit() {
        super.commonInit()
        nameLabel.setStyle(.headline)
    }

    func set(_ name: String?) {
        nameLabel.text = name
    }

    func setAddress(_ address: Address, label: String?) {
        self.address = address
        self.label = label

        identiconView.setAddress(self.address.hexadecimal)
    }
}
