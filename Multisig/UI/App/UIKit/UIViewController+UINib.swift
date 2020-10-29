//
//  UIViewController+UINib.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Creates the view controller from nib named as the `class`. If `class`
    /// is nil, then the view controller's name is used (default).
    /// - Parameter namedClass: class after which name to use as `nibName`.
    /// If nil, then the view controller itself is used (default).
    /// - Returns: newly created view controller
    convenience init(namedClass: AnyClass? = nil) {
        if let aClass = namedClass {
            self.init(nibName: "\(aClass)", bundle: Bundle(for: aClass))
        } else {
            self.init(namedClass: type(of: self))
        }
    }
}
