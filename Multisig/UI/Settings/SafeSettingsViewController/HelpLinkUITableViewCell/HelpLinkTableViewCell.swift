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
    var url: URL?

    @IBAction func openURLButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
