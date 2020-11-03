//
//  CollectiblesHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectiblesHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerNameLabel.setStyle(.headline)
    }

    func configure(collectibleSection: CollectibleListSection) {
        headerNameLabel.text = collectibleSection.name
        let placeholder = #imageLiteral(resourceName: "ico-nft-placeholder")
        if let url = collectibleSection.imageURL {
            headerImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            headerImageView.image = placeholder
        }
    }
}
