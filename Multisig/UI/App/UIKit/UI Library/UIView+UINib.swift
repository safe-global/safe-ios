//
//  UITableViewCell+UINib.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIView {
    /// Get nib by this class's name
    /// - Returns: Nib named the same as the cell's class
    class func nib() -> UINib {
        UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }

    /// Reuse identifier by convention - name of the class itslef
    class var reuseID: String {
        String(describing: self)
    }
}
