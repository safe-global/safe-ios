//
//  DesktopPairingHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DesktopPairingHeaderView: UITableViewHeaderFooterView, ExternalURLSource {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var scanButton: UIButton!
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet private weak var learnMoreLabel: UILabel!

    var onScan: (() -> Void)?
    private(set) var url: URL?

    @IBAction func scan(_ sender: Any) {
        onScan?()
    }

    @IBAction func onLearnMore(_ sender: Any) {
        openExternalURL()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.title3)
        scanButton.setText("Scan QR Code", .filled)
        learnMoreButton.setText("", .plain)
        learnMoreLabel.hyperLinkLabel(linkText: "Learn more")
        url = App.configuration.help.desktopPairingURL
    }
}
