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

    func set(nonce: String) {
        nonceLabel.text = nonce
    }
}
