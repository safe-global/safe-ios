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
        detailLabel.setStyle(.bodyTertiary)
        setProgress(enabled: false)
    }

    func setAddress(_ value: Address, grayscale: Bool = false) {
        if grayscale {
            mainImageView.setAddressGrayscale(value.hexadecimal)
        } else {
            mainImageView.setAddress(value.hexadecimal)
        }
    }

    func setProgress(enabled: Bool) {
        progressIndicator.isHidden = !enabled
    }

    func setDetail(text: String, style: GNOTextStyle = .bodyTertiary) {
        detailLabel.text = text
        detailLabel.setStyle(style)
    }

    func setDetail(address: Address, prefix: String?) {
        detailLabel.text = prefixString(prefix: prefix) + address.ellipsized()
        detailLabel.setStyle(.bodyTertiary)
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
