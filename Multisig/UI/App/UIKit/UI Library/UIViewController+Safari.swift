//
//  UIViewController+Safari.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafariServices

protocol ExternalURLSource {
    var url: URL? { get }
}

extension UIViewController {
    @objc func didTapExternalURL(_ sender: Any) {
        if let sender = sender as? ExternalURLSource, let url = sender.url {
            openInSafari(url)
        }
    }

    func openInSafari(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .formSheet
        present(safari, animated: true)
    }
}
