//
//  UIViewController+Display.swift
//  Multisig
//
//  Created by Mouaz on 9/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
extension UIViewController {
    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .light
    }
}
