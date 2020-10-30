//
//  ScrollableDataErrorView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ScrollableDataErrorView: UINibView {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(GNOTextStyle.title3.color(.gnoMediumGrey))
    }
}
