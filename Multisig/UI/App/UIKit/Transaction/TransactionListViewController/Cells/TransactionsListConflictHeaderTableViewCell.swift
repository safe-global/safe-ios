//
//  TransactionsListConflictHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 12/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionsListConflictHeaderTableViewCell: UITableViewCell {
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    private(set) var url: URL? = URL(string: "https://help.gnosis-safe.io/en/articles/4730252-why-are-transactions-with-the-same-nonce-conflicting-with-each-other")

    override func awakeFromNib() {
        super.awakeFromNib()
        nonceLabel.setStyle(.footnote2)
        descriptionLabel.setStyle(.footnote3)
        learnMoreButton.setText("Learn more", .plain)
    }

    func set(nonce: String) {
        nonceLabel.text = nonce
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        UIApplication.shared.sendAction(#selector(UIViewController.didTapExternalURLCell(_:)), to: nil, from: self, for: nil)
    }
}
