//
//  HeaderContainerView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Container view with the header bar on top of it.
///
/// Why separate container view with a separate header bar?
/// Because UINavigationBar is hard to customize for our purposes
/// due to its different behavior. Instead of customizing it,
/// we built a separate bar and would hide the navigation bar
/// when this view is present on screen
class HeaderContainerView: UINibView {
    @IBOutlet weak var headerBar: HeaderBar!
    @IBOutlet weak var contentView: UIView!

    /// Provides a view to show in the content area beneath the header bar.
    /// If nil is returned, the content is removed from the view.
    var loadContent: () -> UIView? = { nil }

    func update() {
        if let content = loadContent() {
            content.frame = contentView.bounds
            content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(content)
        } else {
            contentView.subviews.forEach { $0.removeFromSuperview() }
        }
    }
}
