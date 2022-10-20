//
//  WebConnectionOwnerView.swift
//  Multisig
//
//  Created by Vitaly on 10.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionOwnerView: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var keyIdenticon: IdenticonView!
    @IBOutlet weak var keyLabel: UILabel!
    
    override func commonInit() {
        super.commonInit()
        backgroundView.layer.cornerRadius = 4
        backgroundView.clipsToBounds = true
        keyLabel.setStyle(.footnote)
        keyLabel.lineBreakMode = .byTruncatingMiddle
    }
    
    func set(name: String, address: Address) {
        keyIdenticon.set(address: address)
        keyLabel.text = "\(name) (\(address.ellipsized(prefix: 6, suffix: 4, checksummed: true)))"
    }
}
