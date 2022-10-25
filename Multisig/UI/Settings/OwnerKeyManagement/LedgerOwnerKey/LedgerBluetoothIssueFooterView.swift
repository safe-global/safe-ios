//
//  LedgerBluetoothIssueFooterView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerBluetoothIssueFooterView: UITableViewHeaderFooterView, ExternalURLSource {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var actionLinkLabel: UILabel!

    private(set) var url: URL?

    static let estimatedHeight: CGFloat = 100

    @IBAction func action(_ sender: Any) {
        openExternalURL()
    }

    override func awakeFromNib() {
        descriptionLabel.setStyle(.body)
    }

    func set(description: String) {
        descriptionLabel.text = description
    }

    func set(link: String?, url: URL?) {
        link == nil ? actionLinkLabel.text = nil : actionLinkLabel.hyperLinkLabel(linkText: link!)
        self.url = url
    }
}
