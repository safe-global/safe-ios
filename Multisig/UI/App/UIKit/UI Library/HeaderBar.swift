//
//  HeaderBar.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Bar with two buttons: one to open info about selected safe,
/// and another to switch between safes.
/// The bar adapts its height to the environment (device, trait collection)
class HeaderBar: UINibView {
    @IBOutlet weak var switchSafeButton: UIButton!
    @IBOutlet weak var safeBarItem: SafeBarItem!

    // TODO: adapt to device screen size
}
