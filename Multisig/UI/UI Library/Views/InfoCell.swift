//
//  InfoCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 10.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoCell: UITableViewCell {
    @IBOutlet private weak var titleLable: UILabel!
    @IBOutlet private weak var infoLable: UILabel!

    static let rowHeight: CGFloat = 44

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLable.setStyle(.headline)
        infoLable.setStyle(.body)
    }

    func setTitle(_ value: String) {
        titleLable.text = value
    }

    func setInfo(_ value: String) {
        infoLable.text = value
    }
}
