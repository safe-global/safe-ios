//
//  ExternalLinkHeaderFooterView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExternalLinkHeaderFooterView: UITableViewHeaderFooterView, ExternalURLSource {
    @IBOutlet weak var openURLButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    private(set) var url: URL?

    @IBAction func openURLButtonTouched(_ sender: Any) {
        openExternalURL()
    }

    func set(label: String) {
        descriptionLabel.hyperLinkLabel(linkText: label)
    }

    func set(url: URL) {
        self.url = url
    }
}
