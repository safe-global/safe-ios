//
//  SafeEntryTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeEntryTableViewCell: UITableViewCell {
    @IBOutlet private weak var mainImageView: UIImageView!
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var selectorView: UIImageView!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.setStyle(.headline)
        detailLabel.setStyle(.tertiary)
    }

    func setAddress(_ value: Address, prefix: String? = nil, deploying: Bool = false) {
      
        if deploying {
            progressIndicator.isHidden = false
            mainImageView.setAddressGrayscale(value.hexadecimal)
            detailLabel.text = "Creating in progress..."
        } else {
            progressIndicator.isHidden = true
            mainImageView.setAddress(value.hexadecimal)
            detailLabel.text = prefixString(prefix: prefix) + value.ellipsized()
        }
    }

    func setName(_ value: String) {
        mainLabel.text = value
    }

    func setSelection(_ value: Bool) {
        selectorView.isHidden = !value
    }

    private func prefixString(prefix: String?) -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }
}
