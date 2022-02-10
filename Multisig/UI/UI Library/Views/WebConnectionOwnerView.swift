//
//  WebConnectionOwnerView.swift
//  Multisig
//
//  Created by Vitaly on 10.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionOwnerView: UINibView {

    @IBOutlet weak var keyIdenticon: IdenticonView!
    @IBOutlet weak var keyLabel: UILabel!
    
    override func commonInit() {
        super.commonInit()
        clipsToBounds = true
        layer.cornerRadius = 4
        keyLabel.setStyle(.footnote3)
    }
    
    func set(name: String, address: Address) {
        keyIdenticon.set(address: address)
        keyLabel.text = "\(name) (\(address.ellipsized(prefix: 4, suffix: 4, checksummed: true)))"
    }
}
