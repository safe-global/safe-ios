//
//  DetailRejectionInfoCell.swift
//  Multisig
//
//  Created by Moaaz on 2/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailRejectionInfoCell: UITableViewCell, ExternalURLSource {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var linkLabel: UILabel!
    @IBOutlet private weak var linkButton: UIButton!

    private(set) var url: URL? = App.configuration.help.payForCancellationURL

    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.setStyle(.primary)
        linkLabel.hyperLinkLabel(linkText: "Why do I need to pay for rejecting a transaction?")
    }
    
    @IBAction func linkButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
