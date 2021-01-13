//
//  SwiftUITableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class SwiftUITableViewCell: UITableViewCell {
    private(set) weak var controller: UIViewController?

    func removeFromParent() {
        if let vc = controller {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            controller = nil
        }
    }

    @discardableResult
    func setContent<Content: View>(_ content: Content, from parent: UIViewController) -> UIHostingController<Content> {
        if let vc = controller {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let vc = UIHostingController(rootView: content)
        parent.addChild(vc)

        var boundsSize = contentView.bounds.size
        boundsSize.height = CGFloat.greatestFiniteMagnitude
        let size = vc.sizeThatFits(in: boundsSize)

        vc.view.backgroundColor = .clear
        vc.view.translatesAutoresizingMaskIntoConstraints = false

        vc.view.frame = CGRect(origin: .zero, size: size)
        contentView.autoresizesSubviews = false
        contentView.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        contentView.setNeedsUpdateConstraints()

        controller = vc

        vc.didMove(toParent: parent)

        return vc
    }
}
