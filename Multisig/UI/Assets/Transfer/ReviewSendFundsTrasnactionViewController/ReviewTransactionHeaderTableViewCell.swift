//
//  ReviewTransactionHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 12/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewTransactionHeaderTableViewCell: UITableViewCell {
    @IBOutlet private weak var fromAddressInfoView: AddressInfoView!
    @IBOutlet private weak var toAddressInfoView: AddressInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
