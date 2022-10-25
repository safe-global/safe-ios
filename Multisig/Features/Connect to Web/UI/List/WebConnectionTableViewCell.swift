//
//  WebConnectionTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class WebConnectionTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ownerKeyView: WebConnectionOwnerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        connectionLabel.setStyle(.footnote)
        statusLabel.setStyle(.footnote)
    }

    func setImage(url: URL?, placeholder: UIImage?) {
        guard let url = url else {
            iconImageView.image = placeholder
            return
        }
        iconImageView.kf.setImage(with: url, placeholder: placeholder)
    }
    
    func setImage(name: String?, placeholder: UIImage?) {
        guard let name = name else {
            iconImageView.image = placeholder
            return
        }
        guard let image = UIImage(named: name) ?? UIImage(systemName: name) else {
            iconImageView.image = placeholder
            return
        }
        iconImageView.image = image
    }

    func setImage(_ image: UIImage?) {
        iconImageView.image = image
    }

    func setHeader(_ text: String?, style: GNOTextStyle = .headline) {
        headerLabel.text = text
        headerLabel.setStyle(style)
    }
    
    func setConnectionInfo(_ text: String?, style: GNOTextStyle = .footnote) {
        connectionLabel.text = text
        connectionLabel.setStyle(style)
    }
    
    func setConnectionTimeInfo(_ text: String?, style: GNOTextStyle = .footnote) {
        guard let text = text else {
            statusIcon.isHidden = true
            statusLabel.isHidden = true
            return
        }
        statusIcon.isHidden = false
        statusLabel.isHidden = false
        statusLabel.text = text
        statusLabel.setStyle(style)
    }
    
    func setKey(_ name: String?, address: Address?) {
        if let address = address, let name = name {
            ownerKeyView.set(name: name, address: address)
        }
        ownerKeyView.isHidden = address == nil
    }
}
