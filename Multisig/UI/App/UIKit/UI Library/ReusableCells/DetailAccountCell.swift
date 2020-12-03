//
//  DetailAccountCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailAccountCell: UITableViewCell {
    @IBOutlet private weak var addressInfoViewWithTitle: AddressInfoViewWithTitle!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoViewWithTitle.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
    }

    func setAccount(addressInfo: AddressInfo, title: String?, onViewDetails: @escaping () -> Void) {
        addressInfoViewWithTitle.setAddressInfo(addressInfo, title: title)
        addressInfoViewWithTitle.onDisclosureButtonAction = onViewDetails
    }
}
