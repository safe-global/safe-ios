//
//  BalanceCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class BalanceCell: UITableViewCell {
    var mainText: String? {
        get { cellMainLabel?.text }
        set { cellMainLabel?.text = newValue }
    }
    var detailText: String? {
        get { cellDetailLabel?.text }
        set { cellDetailLabel?.text = newValue }
    }
    var subDetailText: String? {
        get { cellSubDetailLabel?.text }
        set { cellSubDetailLabel?.text = newValue }
    }
    var image: ImageData? {
        get { cellImageView?.imageData }
        set { cellImageView?.imageData = newValue }
    }

    @IBOutlet private weak var cellMainLabel: GSLabel!
    @IBOutlet private weak var cellDetailLabel: GSLabel!
    @IBOutlet private weak var cellSubDetailLabel: GSLabel!
    @IBOutlet private weak var cellImageView: GSImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellMainLabel.style = .primary
        cellDetailLabel.style = .primary
        cellSubDetailLabel.style = .footnote2

        mainText = nil
        detailText = nil
        subDetailText = nil
        image = nil
    }
}
