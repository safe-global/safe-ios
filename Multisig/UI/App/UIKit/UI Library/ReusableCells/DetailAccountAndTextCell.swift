//
//  DetailAccountAndTextCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailAccountAndTextCell: UITableViewCell {
    @IBOutlet private weak var addressInfoViewWithTitle: AddressInfoViewWithTitle!
    @IBOutlet private weak var textTitleLabel: UILabel!
    @IBOutlet private weak var textDetailsLabel: UILabel!

    private let titleTopSpace: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        textTitleLabel.setStyle(.body)
        textDetailsLabel.setStyle(GNOTextStyle.body.color(.gnoDarkGrey))
        addressInfoViewWithTitle.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
    }

    func setAccount(addressInfo: AddressInfo, title: String?, onViewDetails: @escaping () -> Void) {
        addressInfoViewWithTitle.setAddressInfo(addressInfo, title: title)
        addressInfoViewWithTitle.onDisclosureButtonAction = onViewDetails
    }

    func setText(title: String, details: String) {
        textTitleLabel.text = title
        textDetailsLabel.text = details
    }
}
