//
//  WebConnectionTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    
    @IBOutlet weak var ownerKeyView: WebConnectionOwnerView!
    @IBOutlet weak var statusLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        connectionLabel.setStyle(.secondary)
        statusLabel.setStyle(.secondary)
    }
    
    func setImage(url: URL?, placeholder: UIImage?) {
        guard let url = url else {
            iconImageView.image = placeholder
            return
        }
        iconImageView.kf.setImage(with: url, placeholder: placeholder)
    }

    func setImage(_ image: UIImage?) {
        iconImageView.image = image
    }

    func setHeader(_ text: String?, style: GNOTextStyle = .headline) {
        headerLabel.text = text
        headerLabel.setStyle(style)
    }

//    func setDescription(_ text: String?) {
//        descriptionLabel.text = text
//    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
