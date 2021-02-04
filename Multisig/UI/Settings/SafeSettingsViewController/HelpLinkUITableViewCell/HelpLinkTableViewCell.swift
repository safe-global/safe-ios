//
//  HelpLinkTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 2/4/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class HelpLinkTableViewCell: UITableViewCell, ExternalURLSource {
    @IBOutlet weak var openURLButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    private(set) var url: URL? = App.configuration.help.fallbackHandlerURL
    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.hyperLinkLabel("What is a fallback handler and how does it relate to the Gnosis Safe")
    }

    @IBAction func openURLButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
