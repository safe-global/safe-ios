//
//  UIAlerController+Extension.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func ledgerAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Connectivity Error",
                                      message: "Please unlock your Ledger device and open Ethereum App on it.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        return alert
    }
}
