//
//  ScrollableEmptyView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ScrollableEmptyView: UINibView {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    var refreshControl: UIRefreshControl? {
        get { scrollView.refreshControl }
        set { scrollView.refreshControl = newValue }
    }
    
    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.title3)
    }

    func setText(_ value: String) {
        textLabel.text = value
    }

    func setImage(_ value: UIImage) {
        imageView.image = value
    }
}
