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
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!

    private var onAction: (() -> Void)?

    var refreshControl: UIRefreshControl? {
        get { scrollView.refreshControl }
        set { scrollView.refreshControl = newValue }
    }
    
    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.title3)
        descriptionLabel.setStyle(.subheadlineSecondary)
    }

    func setTitle(_ value: String) {
        titleLabel.text = value
    }

    func setImage(_ value: UIImage) {
        imageView.image = value
    }

    func setDescription(_ value: String?) {
        descriptionLabel.text = value
        descriptionLabel.isHidden = value?.isEmpty ?? true
    }

    func setAction(text: String?, action: @escaping () -> Void) {
        actionButton.setText(text, .filled)
        actionButton.isHidden = text?.isEmpty ?? true
        onAction = action
    }

    @IBAction func didTapAction(_ sender: Any) {
        onAction?()
    }
}
