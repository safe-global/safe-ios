//
//  ContentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Implements a common logic for showing a child view controller
/// and switching between the view controllers - all according to the
/// Apple's documentation
///
/// seeAlso: https://developer.apple.com/documentation/uikit/view_controllers/creating_a_custom_container_view_controller
class ContainerViewController: UIViewController {
    var viewControllers = [UIViewController]()
    private (set) weak var selectedViewController: UIViewController?

    /// Displays a child view controller in the container view
    /// - Parameters:
    ///   - index: index of a child to display. Must be in bounds of the
    ///   `viewControllers` list.
    ///   - containerView: root view for the child's view to embed. Child view
    ///   will have the same bounds as the `containerView`.
    func displayChild(at index: Int, in containerView: UIView) {
        let newVC = viewControllers[index]
        if selectedViewController === newVC {
            // already displaying the child, do nothing
        } else {
            if let currentVC = selectedViewController {
                // removing the existing child view controller
                currentVC.willMove(toParent: nil)
                currentVC.view.removeFromSuperview()
                currentVC.removeFromParent()
            }
            // add new child view controller
            addChild(newVC)
            newVC.view.frame = containerView.bounds
            newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(newVC.view)
            newVC.didMove(toParent: self)
        }
        selectedViewController = newVC
    }
}
