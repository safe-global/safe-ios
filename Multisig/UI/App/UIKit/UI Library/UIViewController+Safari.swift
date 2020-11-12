//
//  UIViewController+Safari.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafariServices

extension UIViewController {
    func openInSafari(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .formSheet
        present(safari, animated: true)
    }
}
