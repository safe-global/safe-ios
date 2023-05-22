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
    @IBOutlet private weak var helpLinkContinerView: UIView!

    private(set) var url: URL? = {
        App.configuration.help.payForCancellationURL
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.setStyle(.body)
        linkLabel.hyperLinkLabel(linkText: "Why do I need to pay for rejecting a transaction?")
    }

    func setNonce(_ nonce: UInt256?, showHelpLink: Bool = true) {
        helpLinkContinerView.isHidden = !showHelpLink
        let base = showHelpLink ?
            "This is an on-chain rejection that doesn’t send any funds. Executing this on-chain rejection will replace all currently awaiting transactions" :
            "This is an on-chain rejection that didn’t send any funds. This on-chain rejection replaced all transactions"
        
        if let nonce = nonce {
            descriptionLabel.text = base + " with nonce \(nonce)."
        } else {
            descriptionLabel.text = base + " with the same nonce."
        }
    }
    
    @IBAction func linkButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
