//
//  TransactionsListConflictHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 12/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionsListConflictHeaderTableViewCell: UITableViewCell, ExternalURLSource {
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!

    private(set) var url: URL? = {
        //FIXME Remove feature flag and flag handling after release
        var url = URL(string: "https://help.safe.global/en/articles/4730252-why-are-transactions-with-the-same-nonce-conflicting-with-each-other")!
        if FirebaseRemoteConfig.shared.boolValue(key: .intercomMigration) ?? false {
            url = App.configuration.help.conflictURL
        }
        return url
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        nonceLabel.setStyle(.footnoteSecondary)
        descriptionLabel.setStyle(.footnoteSecondary)
        learnMoreButton.setText("Learn more", .plain)
    }

    func set(nonce: String) {
        nonceLabel.text = nonce
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
