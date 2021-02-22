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
    @IBOutlet weak var linkButton: UIButton!
    private(set) var url: URL? = App.configuration.help.payForCancellationURL
    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.setStyle(.primary)
        linkLabel.hyperLinkLabel("Why do I need to pay for rejecting a transaction?")
        linkButton.titleLabel?.hyperLinkLabel("Why do I need to pay for rejecting a transaction?")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func linkButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
